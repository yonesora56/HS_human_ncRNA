#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate one two-sample 1D metric from dumped dense matrices.

This wraps h1d.MultiTypeScore.multiScore.obtainTwoScore with datatype=matrix
(the same backend as `h1d two`). One invocation handles one treat/control
pair, one chromosome, and one metric so CWL can scatter later.

h1d call chain:
  multiScore(treat, resolution, chromosome, control_path=control)
    -> obtainTwoScore(metric, parameter, datatype="matrix")
    -> TADScoreChange.getChange / deltaDLR.getDeltaDLR / ...
    -> BasePara.makeDF  (chr, start, end, score)
  Then write a 4-column bedGraph (no header).

Example:
  python3 scripts/hic1dmetrics_score.py \
    --treat-matrix out/h1d/GSE105028_hic/HS_dump/HiC_HS_merged.KR.chr21.5000.matrix.gz \
    --control-matrix out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr21.5000.matrix.gz \
    --chromosome chr21 \
    --resolution 5000 \
    --metric ISC \
    --parameter 300000 \
    --output-bedgraph-file HiC_HS_vs_Ctrl.chr21.ISC.bedGraph
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from h1d.MultiTypeScore import multiScore
import numpy as np

# h1d still uses np.NaN, which NumPy 2 removed
np.NaN = np.nan # type: ignore


MATRIX_METRICS = (
    "ISC",
    "CIC",
    "SSC",
    "deltaDLR",
    "CD",
    "IESC",
    "IASC",
    "DRF",
)
SKIPPED_CHROMOSOMES = {"chrY", "chrM", "chrMT"}


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments for a single-pair, single-chromosome score.

    Returns:
        Parsed arguments: treat_matrix, control_matrix, chromosome, resolution,
        metric, parameter, and output_bedgraph_file.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Calculate one two-sample 1D metric from dumped contact matrices "
            "and write a chromosome bedGraph."
        )
    )
    parser.add_argument(
        "--treat-matrix",
        required=True,
        type=Path,
        help="Dumped treat (e.g. HS) dense matrix .matrix.gz.",
    )
    parser.add_argument(
        "--control-matrix",
        required=True,
        type=Path,
        help="Dumped control dense matrix .matrix.gz.",
    )
    parser.add_argument(
        "--chromosome",
        required=True,
        type=str,
        help="Chromosome name matching the dump files, e.g. chr21.",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=5000,
        help="Bin size in bp. Must match the dumped matrices. Default: 5000.",
    )
    parser.add_argument(
        "--metric",
        required=True,
        choices=MATRIX_METRICS,
        help=(
            "Two-sample metric: ISC, CIC, SSC, deltaDLR, CD, IESC, IASC, or DRF. "
            "IFC is omitted because it requires raw .hic, not dumped matrices."
        ),
    )
    parser.add_argument(
        "--parameter",
        default=None,
        help=(
            "Metric-specific parameter. Integer window for ISC/CIC/SSC/IASC/IESC/"
            "deltaDLR (default 300000, or 3000000 for deltaDLR); correlation "
            "method for CD (default pearson); start,end for DRF "
            "(default 200000,5000000). Omit to use h1d defaults."
        ),
    )
    parser.add_argument(
        "--output-bedgraph-file",
        required=True,
        type=Path,
        help="Output bedGraph path, e.g. HiC_HS_vs_Ctrl.chr21.ISC.bedGraph.",
    )
    return parser.parse_args()


def parse_metric_parameter(metric: str, parameter: str | None) -> int | str | list[int] | None:
    """Convert --parameter text into the type obtainTwoScore expects.

    Args:
        metric: Two-sample metric name (ISC, DRF, CD, ...).
        parameter: Raw CLI string, or None to use h1d defaults.

    Returns:
        None, an int window, a correlation method string, or [start, end] for DRF.

    Raises:
        ValueError: If DRF is not start,end or a numeric metric is not an int.
    """
    if parameter is None:
        return None
    if metric == "CD":
        return parameter
    if metric == "DRF":
        parts = parameter.split(",")
        if len(parts) != 2:
            raise ValueError("DRF --parameter must be start,end e.g. 200000,5000000")
        return [int(parts[0]), int(parts[1])]
    return int(parameter)


def calculate_two_sample_score(
    treat_matrix: Path,
    control_matrix: Path,
    chromosome: str,
    resolution: int,
    metric: str,
    parameter: int | str | list[int] | None,
    output_bedgraph_file: Path,
) -> Path:
    """Calculate one two-sample metric and write a chromosome bedGraph.

    Uses dumped matrices (datatype=matrix), so juicer dump is not repeated.
    Treat is the first matrix (HS); control is the second. The score is
    treat minus control, as in h1d two.

    Args:
        treat_matrix: Dumped treat sample matrix (.matrix.gz).
        control_matrix: Dumped control sample matrix (.matrix.gz).
        chromosome: Chromosome name, e.g. chr21.
        resolution: Bin size in bp; must match both matrices.
        metric: Two-sample metric name supported for matrix input.
        parameter: Metric window/method, or None for h1d defaults.
        output_bedgraph_file: Destination bedGraph path.

    Returns:
        Absolute path of the written bedGraph.

    Raises:
        ValueError: If the chromosome is one that h1d skips.
        FileNotFoundError: If a dumped matrix is missing.
    """
    if chromosome in SKIPPED_CHROMOSOMES:
        raise ValueError(
            f"h1d dump skips {chromosome}; choose another chromosome."
        )

    treat_matrix = treat_matrix.resolve()
    control_matrix = control_matrix.resolve()
    output_bedgraph_file = output_bedgraph_file.resolve()

    if not treat_matrix.is_file():
        raise FileNotFoundError(f"Treat matrix not found: {treat_matrix}")
    if not control_matrix.is_file():
        raise FileNotFoundError(f"Control matrix not found: {control_matrix}")

    score_calculator = multiScore(
        str(treat_matrix),
        resolution,
        chromosome,
        control_path=str(control_matrix),
    )
    score, _, _ = score_calculator.obtainTwoScore(
        metric,
        parameter=parameter,
        datatype="matrix",
    )

    output_bedgraph_file.parent.mkdir(parents=True, exist_ok=True)
    score.to_csv(output_bedgraph_file, sep="\t", header=False, index=False)
    return output_bedgraph_file


def main() -> None:
    """Run two-sample scoring from argparse inputs and print the bedGraph path."""
    args = parse_arguments()
    output_path = calculate_two_sample_score(
        treat_matrix=args.treat_matrix,
        control_matrix=args.control_matrix,
        chromosome=args.chromosome,
        resolution=args.resolution,
        metric=args.metric,
        parameter=parse_metric_parameter(args.metric, args.parameter),
        output_bedgraph_file=args.output_bedgraph_file,
    )
    print(output_path)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
