#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate one one-sample 1D metric from a dumped dense matrix.

This wraps h1d.MultiTypeScore.multiScore.obtainOneScore with datatype=matrix
(the same backend as `h1d one`). One invocation handles one sample, one
chromosome, and one metric so CWL can scatter later.

h1d call chain:
  multiScore(matrix, resolution, chromosome)
    -> obtainOneScore(metric, parameter, datatype="matrix")
    -> InsulationScore.getIS / ContrastIndex.getCI / ...
    -> BasePara.makeDF  (chr, start, end, score)
  Then write a 4-column bedGraph (no header).

Example:
  python3 scripts/hic1dmetrics_score_single_sample.py \
    --matrix out/h1d/GSE105028_hic/Ctrl_dump/HiC_Ctrl_merged.KR.chr21.5000.matrix.gz \
    --chromosome chr21 \
    --resolution 5000 \
    --metric IS \
    --parameter 300000 \
    --output-bedgraph-file HiC_Ctrl_merged.KR.chr21.5000.matrix.IS.bedGraph
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from h1d.MultiTypeScore import multiScore
import numpy as np

# h1d still uses np.NaN, which NumPy 2 removed
np.NaN = np.nan  # type: ignore


MATRIX_METRICS = (
    "IS",
    "CI",
    "DI",
    "SS",
    "DLR",
    "PC1",
    "IES",
    "IAS",
)
SKIPPED_CHROMOSOMES = {"chrY", "chrM", "chrMT"}


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments for a single-sample, single-chromosome score.

    Returns:
        Parsed arguments: matrix, chromosome, resolution, metric, parameter,
        tad_file, and output_bedgraph_file.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Calculate one one-sample 1D metric from a dumped contact matrix "
            "and write a chromosome bedGraph."
        )
    )
    parser.add_argument(
        "--matrix",
        required=True,
        type=Path,
        help="Dumped dense matrix .matrix.gz for one sample and one chromosome.",
    )
    parser.add_argument(
        "--chromosome",
        required=True,
        type=str,
        help="Chromosome name matching the dump file, e.g. chr21.",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=5000,
        help="Bin size in bp. Must match the dumped matrix. Default: 5000.",
    )
    parser.add_argument(
        "--metric",
        required=True,
        choices=MATRIX_METRICS,
        help=(
            "One-sample metric: IS, CI, DI, SS, DLR, PC1, IES, or IAS. "
            "IF is omitted because it requires raw .hic, not dumped matrices."
        ),
    )
    parser.add_argument(
        "--parameter",
        default=None,
        help=(
            "Metric-specific parameter. Integer window for IS/CI/SS/IAS/IES "
            "(default 300000), DI (default 1000000), and DLR (default 3000000). "
            "For PC1, path to a gene-density file (sign is arbitrary if omitted). "
            "Omit to use h1d defaults."
        ),
    )
    parser.add_argument(
        "--tad-file",
        default=None,
        type=Path,
        help=(
            "Optional TAD BED for IAS/IES instead of the built-in TAD caller "
            "(h1d one --TADfile)."
        ),
    )
    parser.add_argument(
        "--output-bedgraph-file",
        required=True,
        type=Path,
        help="Output bedGraph path, e.g. HiC_Ctrl_merged.KR.chr21.5000.matrix.IS.bedGraph.",
    )
    return parser.parse_args()


def parse_metric_parameter(metric: str, parameter: str | None) -> int | str | None:
    """Convert --parameter text into the type obtainOneScore expects.

    Args:
        metric: One-sample metric name (IS, PC1, ...).
        parameter: Raw CLI string, or None to use h1d defaults.

    Returns:
        None, an int window, or a gene-density path string for PC1.

    Raises:
        ValueError: If a numeric metric is not an int.
    """
    if parameter is None:
        return None
    if metric == "PC1":
        return parameter
    return int(parameter)


def calculate_one_sample_score(
    matrix: Path,
    chromosome: str,
    resolution: int,
    metric: str,
    parameter: int | str | None,
    output_bedgraph_file: Path,
    tad_file: Path | None = None,
) -> Path:
    """Calculate one one-sample metric and write a chromosome bedGraph.

    Uses a dumped matrix (datatype=matrix), so juicer dump is not repeated.

    Args:
        matrix: Dumped sample matrix (.matrix.gz).
        chromosome: Chromosome name, e.g. chr21.
        resolution: Bin size in bp; must match the matrix.
        metric: One-sample metric name supported for matrix input.
        parameter: Metric window or PC1 gene-density path, or None for defaults.
        output_bedgraph_file: Destination bedGraph path.
        tad_file: Optional TAD BED for IAS/IES.

    Returns:
        Absolute path of the written bedGraph.

    Raises:
        ValueError: If the chromosome is one that h1d skips.
        FileNotFoundError: If the dumped matrix or an optional input file is missing.
    """
    if chromosome in SKIPPED_CHROMOSOMES:
        raise ValueError(
            f"h1d dump skips {chromosome}; choose another chromosome."
        )

    matrix = matrix.resolve()
    output_bedgraph_file = output_bedgraph_file.resolve()

    if not matrix.is_file():
        raise FileNotFoundError(f"Matrix not found: {matrix}")

    tad_path = None
    if tad_file is not None:
        tad_file = tad_file.resolve()
        if not tad_file.is_file():
            raise FileNotFoundError(f"TAD file not found: {tad_file}")
        tad_path = str(tad_file)

    pc1_gene_density = None
    if metric == "PC1" and isinstance(parameter, str):
        pc1_gene_density = Path(parameter).resolve()
        if not pc1_gene_density.is_file():
            raise FileNotFoundError(f"PC1 gene-density file not found: {pc1_gene_density}")
        parameter = str(pc1_gene_density)

    score_calculator = multiScore(
        str(matrix),
        resolution,
        chromosome,
    )
    score = score_calculator.obtainOneScore(
        metric,
        parameter=parameter,
        datatype="matrix",
        TADfile=tad_path,
    )

    output_bedgraph_file.parent.mkdir(parents=True, exist_ok=True)
    score.to_csv(output_bedgraph_file, sep="\t", header=False, index=False)
    return output_bedgraph_file


def main() -> None:
    """Run one-sample scoring from argparse inputs and print the bedGraph path."""
    args = parse_arguments()
    output_path = calculate_one_sample_score(
        matrix=args.matrix,
        chromosome=args.chromosome,
        resolution=args.resolution,
        metric=args.metric,
        parameter=parse_metric_parameter(args.metric, args.parameter),
        output_bedgraph_file=args.output_bedgraph_file,
        tad_file=args.tad_file,
    )
    print(output_path)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
