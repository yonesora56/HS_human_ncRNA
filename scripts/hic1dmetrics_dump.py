#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Dump one intra-chromosomal dense matrix from a Juicer .hic file.
This wraps the same makeMatrixIntra.sh used by `h1d basic dump`.
One invocation handles one sample and one chromosome so CWL can scatter later.

Example:
  python3 scripts/hic1dmetrics_dump.py \
    --hic-file out/hic/GSE105028_hic_convert_hic/HiC_Ctrl_merged_juicer_pre_output/HiC_Ctrl_merged.hic \
    --genome-table out/hic/hg38_genome_table.txt \
    --juicer-tools juicer_tools.2.20.00.jar \
    --chromosome chr21 \
    --resolution 5000 \
    --normalize KR \
    --output-matrix-file observed.KR.chr21.matrix.gz
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import h1d


MAKE_MATRIX_INTRA = (
    Path(h1d.__file__).resolve().parent / "extract" / "makeMatrixIntra.sh"
)
SKIPPED_CHROMOSOMES = {"chrY", "chrM", "chrMT"}


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments for a single-sample, single-chromosome dump.

    Returns:
        Parsed arguments: hic_file, genome_table, juicer_tools, chromosome,
        resolution, normalize, and output_matrix_file.
    """
    parser = argparse.ArgumentParser(
        description="Dump a dense contact matrix for one Hi-C sample and one chromosome."
    )
    parser.add_argument(
        "--hic-file",
        required=True,
        type=Path,
        help="Input Juicer .hic file.",
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
        help="Bin size in bp. Default: 5000.",
    )
    parser.add_argument(
        "--normalize",
        choices=["NONE", "VC", "VC_SQRT", "KR"],
        default="KR",
        help="Juicer dump normalization. Default: KR.",
    )
    parser.add_argument(
        "--output-matrix-file",
        required=True,
        type=Path,
        help="Output dense matrix path (.matrix.gz), e.g. observed.KR.chr21.matrix.gz.",
    )
    return parser.parse_args()


def dump_hic_matrix(
    hic_file: Path,
    genome_table: Path,
    juicer_tools: Path,
    chromosome: str,
    resolution: int,
    normalize: str,
    output_matrix_file: Path,
) -> Path:
    """Dump one intra-chromosomal dense matrix from a .hic file.

    Runs h1d's makeMatrixIntra.sh (same backend as `h1d basic dump`) for a
    single chromosome, then copies the gzipped matrix to output_matrix_file.
    Chromosome names must match the genome table (e.g. chr21). chrY, chrM,
    and chrMT are rejected because h1d skips them.

    Args:
        hic_file: Juicer .hic file to dump.
        genome_table: Tab-separated chromosome-length file for h1d --gt.
        juicer_tools: juicer_tools jar (2.20.00 for HIC v9).
        chromosome: Chromosome name, e.g. chr21.
        resolution: Bin size in bp.
        normalize: Juicer normalization (NONE, VC, VC_SQRT, or KR).
        output_matrix_file: Destination path for the .matrix.gz file.

    Returns:
        Absolute path of the copied output matrix.

    Raises:
        ValueError: If the chromosome is one that h1d skips.
        FileNotFoundError: If makeMatrixIntra.sh or the dumped matrix is missing.
        subprocess.CalledProcessError: If makeMatrixIntra.sh exits non-zero.
    """
    if chromosome in SKIPPED_CHROMOSOMES:
        raise ValueError(
            f"h1d dump skips {chromosome}; choose another chromosome.")
    if not MAKE_MATRIX_INTRA.is_file():
        raise FileNotFoundError(
            f"makeMatrixIntra.sh not found: {MAKE_MATRIX_INTRA}")

    hic_file = hic_file.resolve()
    genome_table = genome_table.resolve()
    juicer_tools = juicer_tools.resolve()
    output_matrix_file = output_matrix_file.resolve()

    chromosome_id = chromosome.removeprefix("chr")
    dumped_name = f"observed.{normalize}.chr{chromosome_id}.matrix.gz"

    with tempfile.TemporaryDirectory(prefix="h1d_dump_") as tmp:
        tmp_dir = Path(tmp)
        subprocess.run(
            [
                "bash",
                str(MAKE_MATRIX_INTRA),
                normalize,
                str(tmp_dir),
                str(hic_file),
                str(resolution),
                str(genome_table),
                str(juicer_tools),
                chromosome,
                "dump",
            ],
            cwd=tmp_dir,
            check=True,
        )
        dumped_matrix = tmp_dir / "dump" / str(resolution) / dumped_name
        if not dumped_matrix.is_file():
            raise FileNotFoundError(
                f"Dump finished but matrix was not created: {dumped_matrix}"
            )
        output_matrix_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dumped_matrix, output_matrix_file)

    return output_matrix_file


def main() -> None:
    """Run dump from argparse inputs and print the output matrix path."""
    args = parse_arguments()
    output_path = dump_hic_matrix(
        hic_file=args.hic_file,
        genome_table=args.genome_table,
        juicer_tools=args.juicer_tools,
        chromosome=args.chromosome,
        resolution=args.resolution,
        normalize=args.normalize,
        output_matrix_file=args.output_matrix_file,
    )
    print(output_path)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError, subprocess.CalledProcessError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
