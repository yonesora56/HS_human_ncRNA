#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate one two-sample 1D metric from a pair of Juicer .hic files.

This wraps h1d.MultiTypeScore.multiScore.obtainTwoScore with datatype=rawhic
(the same backend as `h1d two --datatype rawhic`). One invocation handles one
treat/control pair, one chromosome, and one metric so CWL can scatter later.

h1d call chain:
  multiScore(treat.hic, resolution, chromosome, control_path=control.hic, juicer=jar)
    -> obtainTwoScore(metric, parameter, datatype="rawhic", gt=genome_table)
    -> hic2matrix dumps KR dense matrices (except IFC)
    -> TADScoreChange.getChange / deltaDLR.getDeltaDLR / InteractionFrequencyChange.getIFC / ...
    -> BasePara.makeDF  (chr, start, end, score)
  Then write a 4-column bedGraph (no header).

hic2matrix always uses KR dump. Pass juicer_tools 2.20.00 for HIC v9; the
built-in 1.11.04 jar cannot read these files.

Example:
  python3 scripts/hic1dmetrics_score_rawhic.py \
    --treat-hic out/hic/GSE105028_hic_convert_hic/HiC_HS_merged_juicer_pre_output/HiC_HS_merged.hic \
    --control-hic out/hic/GSE105028_hic_convert_hic/HiC_Ctrl_merged_juicer_pre_output/HiC_Ctrl_merged.hic \
    --genome-table out/h1d/hg38_genome_table.txt \
    --juicer-tools out/h1d/juicer_tools.2.20.00.jar \
    --chromosome chr21 \
    --resolution 5000 \
    --metric ISC \
    --parameter 300000 \
    --output-bedgraph-file HiC_HS_vs_Ctrl.chr21.ISC.bedGraph
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

from h1d.MultiTypeScore import multiScore
import numpy as np

# h1d still uses np.NaN, which NumPy 2 removed
np.NaN = np.nan  # type: ignore


RAWHIC_METRICS = (
    "ISC",
    "CIC",
    "SSC",
    "deltaDLR",
    "CD",
    "IESC",
    "IASC",
    "DRF",
    "IFC",
)
SKIPPED_CHROMOSOMES = {"chrY", "chrM", "chrMT"}


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments for a single-pair, single-chromosome score.

    Returns:
        Parsed arguments: treat_hic, control_hic, genome_table, juicer_tools,
        chromosome, resolution, metric, parameter, and output_bedgraph_file.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Calculate one two-sample 1D metric from a pair of Juicer .hic files "
            "and write a chromosome bedGraph."
        )
    )
    parser.add_argument(
        "--treat-hic",
        required=True,
        type=Path,
        help="Treat (e.g. HS) Juicer .hic file.",
    )
    parser.add_argument(
        "--control-hic",
        required=True,
        type=Path,
        help="Control Juicer .hic file.",
    )
    parser.add_argument(
        "--genome-table",
        required=True,
        type=Path,
        help="Tab-separated genome table (chromosome, length) for h1d --gt.",
    )
    parser.add_argument(
        "--juicer-tools",
        required=True,
        type=Path,
        help="Path to juicer_tools jar (use 2.20.00 for HIC v9 files).",
    )
    parser.add_argument(
        "--chromosome",
        required=True,
        type=str,
        help="Chromosome name matching the genome table, e.g. chr21.",
    )
    parser.add_argument(
        "--resolution",
        type=int,
        default=5000,
        help="Bin size in bp. Must exist in both .hic files. Default: 5000.",
    )
    parser.add_argument(
        "--metric",
        required=True,
        choices=RAWHIC_METRICS,
        help=(
            "Two-sample metric: ISC, CIC, SSC, deltaDLR, CD, IESC, IASC, DRF, "
            "or IFC. IFC is available here because it requires raw .hic."
        ),
    )
    parser.add_argument(
        "--parameter",
        default=None,
        help=(
            "Metric-specific parameter. Integer window for ISC/CIC/SSC/IASC/IESC/"
            "deltaDLR (default 300000, or 3000000 for deltaDLR); correlation "
            "method for CD (default pearson); start,end for DRF "
            "(default 200000,5000000). IFC ignores this flag in h1d. "
            "Omit to use h1d defaults."
        ),
    )
    parser.add_argument(
        "--output-bedgraph-file",
        required=True,
        type=Path,
        help="Output bedGraph path, e.g. HiC_HS_vs_Ctrl.chr21.ISC.bedGraph.",
    )
    return parser.parse_args()


def parse_metric_parameter(metric: str, parameter: str | None) -> int | str | list[int] | float | None:
    """Convert --parameter text into the type obtainTwoScore expects.

    Args:
        metric: Two-sample metric name (ISC, DRF, CD, IFC, ...).
        parameter: Raw CLI string, or None to use h1d defaults.

    Returns:
        None, an int window, a correlation method string, [start, end] for DRF,
        or a float for IFC (unused by h1d, kept for CLI symmetry).

    Raises:
        ValueError: If DRF is not start,end or a numeric metric is not a number.
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
    if metric == "IFC":
        return float(parameter)
    return int(parameter)


def calculate_two_sample_score_rawhic(
    treat_hic: Path,
    control_hic: Path,
    genome_table: Path,
    juicer_tools: Path,
    chromosome: str,
    resolution: int,
    metric: str,
    parameter: int | str | list[int] | float | None,
    output_bedgraph_file: Path,
) -> Path:
    """Calculate one two-sample metric from .hic files and write a bedGraph.

    Uses datatype=rawhic. For metrics other than IFC, h1d dumps KR matrices
    via hic2matrix then scores them. Treat is the first .hic (HS); control is
    the second. The score is treat minus control, as in h1d two.

    Temporary dump directories (MatrixTemp*) are created inside a tempfile so
    they do not remain in the caller working directory.

    Args:
        treat_hic: Treat sample Juicer .hic file.
        control_hic: Control sample Juicer .hic file.
        genome_table: Tab-separated chromosome-length file for h1d --gt.
        juicer_tools: juicer_tools jar (2.20.00 for HIC v9).
        chromosome: Chromosome name, e.g. chr21.
        resolution: Bin size in bp; must exist in both .hic files.
        metric: Two-sample metric name supported for rawhic input.
        parameter: Metric window/method, or None for h1d defaults.
        output_bedgraph_file: Destination bedGraph path.

    Returns:
        Absolute path of the written bedGraph.

    Raises:
        ValueError: If the chromosome is one that h1d skips.
        FileNotFoundError: If a required input file is missing.
    """
    if chromosome in SKIPPED_CHROMOSOMES:
        raise ValueError(
            f"h1d dump skips {chromosome}; choose another chromosome."
        )

    treat_hic = treat_hic.resolve()
    control_hic = control_hic.resolve()
    genome_table = genome_table.resolve()
    juicer_tools = juicer_tools.resolve()
    output_bedgraph_file = output_bedgraph_file.resolve()

    if not treat_hic.is_file():
        raise FileNotFoundError(f"Treat hic not found: {treat_hic}")
    if not control_hic.is_file():
        raise FileNotFoundError(f"Control hic not found: {control_hic}")
    if not genome_table.is_file():
        raise FileNotFoundError(f"Genome table not found: {genome_table}")
    if not juicer_tools.is_file():
        raise FileNotFoundError(f"juicer_tools jar not found: {juicer_tools}")

    ifc_parameter = None if metric == "IFC" else parameter

    original_cwd = Path.cwd()
    with tempfile.TemporaryDirectory(prefix="h1d_score_rawhic_") as tmp:
        os.chdir(tmp)
        try:
            score_calculator = multiScore(
                str(treat_hic),
                resolution,
                chromosome,
                control_path=str(control_hic),
                juicer=str(juicer_tools),
            )
            score, _, _ = score_calculator.obtainTwoScore(
                metric,
                parameter=ifc_parameter,
                datatype="rawhic",
                gt=str(genome_table),
            )
        finally:
            os.chdir(original_cwd)

    output_bedgraph_file.parent.mkdir(parents=True, exist_ok=True)
    score.to_csv(output_bedgraph_file, sep="\t", header=False, index=False)
    return output_bedgraph_file


def main() -> None:
    """Run two-sample scoring from argparse inputs and print the bedGraph path."""
    args = parse_arguments()
    output_path = calculate_two_sample_score_rawhic(
        treat_hic=args.treat_hic,
        control_hic=args.control_hic,
        genome_table=args.genome_table,
        juicer_tools=args.juicer_tools,
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
