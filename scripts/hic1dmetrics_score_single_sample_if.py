#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate one-sample Interaction Frequency (IF) from a Juicer .hic file.

h1d's `h1d one IF` requires datatype=rawhic. obtainOneScore hardcodes juicer
1.11.04, which cannot read HIC v9, so this script does not call
obtainOneScore. It follows InteractionFreq.sh (Fit-Hi-C, FDR 0.05, then
per-bin coverage) and dumps with the caller-supplied juicer jar (use 2.20.00).

One invocation handles one sample and one chromosome so CWL can scatter later.

h1d-equivalent chain:
  juicer dump observed KR (retry chr21 if 21 is invalid)
    -> Fit-Hi-C (fithic)
    -> significant loci (q < FDR)
    -> per-bin coverage (bedtools coverage in the original shell)
    -> log1p / mean of positive values
  Then write a 4-column bedGraph (no header).

Example:
  python3 scripts/hic1dmetrics_score_single_sample_if.py \
    --hic-file out/hic/GSE105028_hichip_convert_hic/CTCF_HS_merged_juicer_pre_output/CTCF_HS_merged.hic \
    --genome-table out/h1d/hg38_genome_table.txt \
    --juicer-tools out/h1d/juicer_tools.2.20.00.jar \
    --chromosome chr21 \
    --resolution 5000 \
    --output-bedgraph-file CTCF_HS_merged.chr21.IF.bedGraph \
    --output-significances-file CTCF_HS_merged.chr21.IF.significances.txt \
    --output-fithic-pass1-file CTCF_HS_merged.chr21.IF.fithic_pass1.txt
"""

from __future__ import annotations

import argparse
import gzip
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import pandas as pd

SKIPPED_CHROMOSOMES = {"chrY", "chrM", "chrMT"}
JAVA_XMX = "20480m"
FITHIC_FDR_DEFAULT = 0.05


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments for a single-sample, single-chromosome IF.

    Returns:
        Parsed arguments: hic_file, genome_table, juicer_tools, chromosome,
        resolution, fdr_threshold, output_bedgraph_file,
        output_significances_file, and output_fithic_pass1_file.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Calculate one-sample Interaction Frequency (IF) from a Juicer "
            ".hic file and write a chromosome bedGraph."
        )
    )
    parser.add_argument(
        "--hic-file",
        required=True,
        type=Path,
        help="Input Juicer .hic file (IF cannot use dumped matrices).",
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
        help="Bin size in bp. Must exist in the .hic file. Default: 5000.",
    )
    parser.add_argument(
        "--fdr-threshold",
        type=float,
        default=FITHIC_FDR_DEFAULT,
        help=(
            "Fit-Hi-C q-value cutoff (h1d InteractionFreq.sh uses 0.05). "
            "Default: 0.05."
        ),
    )
    parser.add_argument(
        "--output-bedgraph-file",
        required=True,
        type=Path,
        help="Output bedGraph path, e.g. CTCF_HS_merged.chr21.IF.bedGraph.",
    )
    parser.add_argument(
        "--output-significances-file",
        required=True,
        type=Path,
        help=(
            "Copy of Fit-Hi-C significances table (uncompressed TSV), e.g. "
            "CTCF_HS_merged.chr21.IF.significances.txt."
        ),
    )
    parser.add_argument(
        "--output-fithic-pass1-file",
        required=True,
        type=Path,
        help=(
            "Copy of FitHiC.fithic_pass1.res{resolution}.txt (uncompressed TSV), "
            "e.g. CTCF_HS_merged.chr21.IF.fithic_pass1.txt."
        ),
    )
    return parser.parse_args()


def seq_inclusive(start: int, step: int, stop: int) -> np.ndarray:
    """Match GNU seq START STEP STOP (inclusive upper bound).

    Args:
        start: First value.
        step: Positive increment.
        stop: Inclusive maximum.

    Returns:
        Integer sequence start, start+step, ... while value <= stop.
    """
    if step <= 0:
        raise ValueError("step must be a positive integer")
    if stop < start:
        return np.array([], dtype=int)
    n = (stop - start) // step + 1
    return start + step * np.arange(n, dtype=int)


def chromosome_length(genome_table: Path, chromosome: str) -> int:
    """Read chromosome length from a two-column tab-separated genome table.

    Args:
        genome_table: Path to chromosome, length TSV (no header).
        chromosome: Name to match in column 1, e.g. chr21.

    Returns:
        Chromosome length in bp.

    Raises:
        ValueError: If the chromosome is missing or the length is not an int.
    """
    table = pd.read_csv(genome_table, sep="\t", header=None)
    chrom_names = table.iloc[:, 0]
    chrom_lengths = table.iloc[:, 1]
    matched = chrom_lengths.loc[chrom_names == chromosome]
    if matched.empty:
        raise ValueError(f"Chromosome {chromosome} not in genome table: {genome_table}")
    return int(matched.iloc[0])


def dump_observed_kr(
    hic_file: Path,
    juicer_tools: Path,
    chromosome: str,
    resolution: int,
    dump_file: Path,
) -> None:
    """Dump sparse observed KR contacts, retrying chr prefix like makeMatrixIntra.sh.

    Args:
        hic_file: Juicer .hic file.
        juicer_tools: juicer_tools jar.
        chromosome: Name with or without chr prefix.
        resolution: Bin size in bp.
        dump_file: Destination sparse dump (bin1, bin2, count).

    Raises:
        RuntimeError: If both chromosome spellings fail or the dump is empty.
    """
    chromosome_id = chromosome.removeprefix("chr")
    java = [
        "java",
        "-Xms512m",
        f"-Xmx{JAVA_XMX}",
        "-jar",
        str(juicer_tools),
        "dump",
        "observed",
        "KR",
        str(hic_file),
    ]
    last_error = ""
    for chrom in (chromosome_id, f"chr{chromosome_id}"):
        result = subprocess.run(
            [*java, chrom, chrom, "BP", str(resolution), str(dump_file)],
            check=False,
            capture_output=True,
            text=True,
        )
        last_error = (result.stderr or result.stdout or "").strip()
        if result.returncode == 0 and dump_file.is_file() and dump_file.stat().st_size > 0:
            return
    raise RuntimeError(
        "juicer dump observed KR failed for "
        f"{chromosome_id} and chr{chromosome_id}. {last_error}"
    )


def write_fithic_inputs(
    dump_file: Path,
    chromosome_id: str,
    resolution: int,
    chrom_length: int,
    interactions_gz: Path,
    fragments_gz: Path,
) -> None:
    """Convert a juicer sparse dump into Fit-Hi-C interaction and fragment files.

    Matches InteractionFreq.sh steps 2-3 (NaN -> 0; fragment mids at res/2).

    Args:
        dump_file: Sparse juicer dump.
        chromosome_id: Numeric chromosome id passed to Fit-Hi-C (e.g. 21).
        resolution: Bin size in bp.
        chrom_length: Chromosome length from the genome table.
        interactions_gz: Output gzipped 5-column contacts.
        fragments_gz: Output gzipped fragment file.
    """
    dump = pd.read_csv(dump_file, sep="\t", header=None)
    bin1 = dump.iloc[:, 0]
    bin2 = dump.iloc[:, 1]
    count = pd.Series(pd.to_numeric(dump.iloc[:, 2], errors="coerce")).fillna(0)
    with gzip.open(interactions_gz, "wt") as handle:
        for start1, start2, contact in zip(bin1, bin2, count, strict=True):
            handle.write(
                f"{chromosome_id}\t{int(start1)}\t{chromosome_id}\t{int(start2)}\t{contact}\n"
            )

    end_length = chrom_length + resolution
    starts = seq_inclusive(0, resolution, chrom_length)
    mids = seq_inclusive(resolution // 2, resolution, end_length)
    n_frag = min(len(starts), len(mids))
    with gzip.open(fragments_gz, "wt") as handle:
        for start, mid in zip(starts[:n_frag], mids[:n_frag]):
            handle.write(f"{chromosome_id}\t{int(start)}\t{int(mid)}\t1\t1\n")


def run_fithic(
    interactions_gz: Path,
    fragments_gz: Path,
    resolution: int,
    out_dir: Path,
) -> Path:
    """Run Fit-Hi-C and return the significances table.

    Args:
        interactions_gz: Fit-Hi-C interactions file.
        fragments_gz: Fit-Hi-C fragments file.
        resolution: Bin size in bp.
        out_dir: Directory for Fit-Hi-C outputs.

    Returns:
        Path to the significances table (.txt or .txt.gz).

    Raises:
        FileNotFoundError: If fithic did not write a significances table.
        subprocess.CalledProcessError: If fithic exits non-zero.
    """
    subprocess.run(
        [
            "fithic",
            "-i",
            str(interactions_gz),
            "-f",
            str(fragments_gz),
            "-r",
            str(resolution),
            "-o",
            str(out_dir),
        ],
        cwd=out_dir,
        check=True,
    )
    gzipped = sorted(out_dir.glob("*.significances.txt.gz"))
    plain = sorted(out_dir.glob("*.significances.txt"))
    matches = gzipped if gzipped else plain
    if not matches:
        raise FileNotFoundError(f"Fit-Hi-C finished but no significances file in {out_dir}")
    return matches[0]


def find_fithic_pass1_table(out_dir: Path) -> Path:
    """Locate FitHiC.fithic_pass1.res{resolution}.txt written by Fit-Hi-C.

    Args:
        out_dir: Directory for Fit-Hi-C outputs.

    Returns:
        Path to the pass-1 contact/bin table (.txt or .txt.gz).

    Raises:
        FileNotFoundError: If the pass-1 table is missing.
    """
    gzipped = sorted(out_dir.glob("*.fithic_pass1*.txt.gz"))
    plain = sorted(out_dir.glob("*.fithic_pass1*.txt"))
    matches = gzipped if gzipped else plain
    if not matches:
        raise FileNotFoundError(f"Fit-Hi-C finished but no fithic_pass1 file in {out_dir}")
    return matches[0]


def copy_significances_table(source: Path, destination: Path) -> Path:
    """Copy a Fit-Hi-C text table to destination as uncompressed TSV.

    Args:
        source: Table from the Fit-Hi-C working directory (.txt or .txt.gz).
        destination: Output path.

    Returns:
        Absolute path of the copied table.
    """
    destination = destination.resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.name.endswith(".gz"):
        with gzip.open(source, "rb") as handle_in, destination.open("wb") as handle_out:
            shutil.copyfileobj(handle_in, handle_out)
    else:
        shutil.copy2(source, destination)
    return destination


def significant_anchor_starts(significances_file: Path, fdr_threshold: float) -> np.ndarray:
    """Collect fragment midpoints with q-value below the FDR cutoff.

    h1d awk uses column 7 as the q-value and concatenates columns 2 and 4
    (the two interacting loci).

    Args:
        significances_file: Fit-Hi-C significances table (.txt or .txt.gz).
        fdr_threshold: Maximum q-value to keep.

    Returns:
        1D array of locus coordinates (bp), possibly empty.
    """
    table = pd.read_csv(significances_file, sep="\t", header=None, comment="#")
    if table.shape[1] < 7:
        raise ValueError(
            f"Fit-Hi-C significances need >= 7 columns, got {table.shape[1]}: "
            f"{significances_file}"
        )
    qvalues = pd.Series(pd.to_numeric(table.iloc[:, 6], errors="coerce"), index=table.index)
    kept = table.loc[qvalues < fdr_threshold]
    left = pd.Series(pd.to_numeric(kept.iloc[:, 1], errors="coerce"))
    right = pd.Series(pd.to_numeric(kept.iloc[:, 3], errors="coerce"))
    anchors = pd.concat([left, right], ignore_index=True).dropna()
    return anchors.astype(int).to_numpy()


def coverage_bedgraph(
    chromosome: str,
    chrom_length: int,
    resolution: int,
    anchor_starts: np.ndarray,
) -> pd.DataFrame:
    """Count significant anchors overlapping each genomic bin.

    Replaces `bedtools coverage -a genome.split -b Anchor.bed | cut -f 1-4`
    from InteractionFreq.sh.

    Args:
        chromosome: Output chromosome name, e.g. chr21.
        chrom_length: Chromosome length in bp.
        resolution: Bin size in bp.
        anchor_starts: Locus starts of significant interactions.

    Returns:
        DataFrame with columns chr, start, end, InteractionFrequency (raw counts).
    """
    end_length = chrom_length + resolution
    bin_starts = seq_inclusive(0, resolution, chrom_length)
    bin_ends = seq_inclusive(resolution, resolution, end_length)
    n_bin = min(len(bin_starts), len(bin_ends))
    bin_starts = bin_starts[:n_bin]
    bin_ends = bin_ends[:n_bin]
    counts = np.zeros(n_bin, dtype=int)
    if anchor_starts.size:
        # Anchors are [pos, pos + resolution), same as the original awk.
        for pos in anchor_starts:
            a0 = int(pos)
            a1 = a0 + resolution
            i0 = int(np.searchsorted(bin_ends, a0, side="right"))
            i1 = int(np.searchsorted(bin_starts, a1, side="left"))
            if i0 < i1:
                counts[i0:i1] += 1
    return pd.DataFrame(
        {
            "chr": chromosome,
            "start": bin_starts,
            "end": bin_ends,
            "InteractionFrequency": counts,
        }
    )


def normalize_interaction_frequency(score: pd.DataFrame) -> pd.DataFrame:
    """Apply h1d IF normalization: log1p / mean of positive log1p values.

    Args:
        score: Four-column bedGraph with raw coverage in column InteractionFrequency.

    Returns:
        The same DataFrame with the score column replaced by the normalized values.
    """
    before_log = score["InteractionFrequency"].to_numpy(dtype=float)
    after_log = np.log1p(before_log)
    positive = after_log[after_log > 0]
    if positive.size:
        after_log = after_log / np.mean(positive)
    score = score.copy()
    score["InteractionFrequency"] = after_log
    return score


def calculate_interaction_frequency(
    hic_file: Path,
    genome_table: Path,
    juicer_tools: Path,
    chromosome: str,
    resolution: int,
    output_bedgraph_file: Path,
    output_significances_file: Path,
    output_fithic_pass1_file: Path,
    fdr_threshold: float = FITHIC_FDR_DEFAULT,
) -> Path:
    """Calculate IF for one .hic file and one chromosome, then write a bedGraph.

    Args:
        hic_file: Juicer .hic file.
        genome_table: Tab-separated chromosome-length file.
        juicer_tools: juicer_tools jar (2.20.00 for HIC v9).
        chromosome: Chromosome name, e.g. chr21.
        resolution: Bin size in bp.
        output_bedgraph_file: Destination bedGraph path.
        output_significances_file: Destination Fit-Hi-C significances TSV.
        output_fithic_pass1_file: Destination Fit-Hi-C pass-1 table TSV.
        fdr_threshold: Fit-Hi-C q-value cutoff (h1d default 0.05).

    Returns:
        Absolute path of the written bedGraph.

    Raises:
        ValueError: If the chromosome is skipped by h1d or missing from the table.
        FileNotFoundError: If a required input file is missing.
    """
    if chromosome in SKIPPED_CHROMOSOMES:
        raise ValueError(
            f"h1d dump skips {chromosome}; choose another chromosome."
        )

    hic_file = hic_file.resolve()
    genome_table = genome_table.resolve()
    juicer_tools = juicer_tools.resolve()
    output_bedgraph_file = output_bedgraph_file.resolve()
    output_significances_file = output_significances_file.resolve()
    output_fithic_pass1_file = output_fithic_pass1_file.resolve()

    if not hic_file.is_file():
        raise FileNotFoundError(f"hic file not found: {hic_file}")
    if not genome_table.is_file():
        raise FileNotFoundError(f"Genome table not found: {genome_table}")
    if not juicer_tools.is_file():
        raise FileNotFoundError(f"juicer_tools jar not found: {juicer_tools}")

    chrom_length = chromosome_length(genome_table, chromosome)
    chromosome_id = chromosome.removeprefix("chr")

    with tempfile.TemporaryDirectory(prefix="h1d_if_") as tmp:
        tmp_dir = Path(tmp)
        dump_file = tmp_dir / "dump.temp.txt"
        dump_observed_kr(hic_file, juicer_tools, chromosome, resolution, dump_file)
        interactions_gz = tmp_dir / "fithic.temp.gz"
        fragments_gz = tmp_dir / "fragment.temp.gz"
        write_fithic_inputs(
            dump_file,
            chromosome_id,
            resolution,
            chrom_length,
            interactions_gz,
            fragments_gz,
        )
        significances = run_fithic(
            interactions_gz, fragments_gz, resolution, tmp_dir
        )
        copy_significances_table(significances, output_significances_file)
        copy_significances_table(
            find_fithic_pass1_table(tmp_dir), output_fithic_pass1_file
        )
        anchor_starts = significant_anchor_starts(significances, fdr_threshold)
        score = coverage_bedgraph(
            chromosome, chrom_length, resolution, anchor_starts
        )
        score = normalize_interaction_frequency(score)

    output_bedgraph_file.parent.mkdir(parents=True, exist_ok=True)
    score.to_csv(output_bedgraph_file, sep="\t", header=False, index=False)
    return output_bedgraph_file


def main() -> None:
    """Run IF scoring from argparse inputs and print the bedGraph path."""
    args = parse_arguments()
    output_path = calculate_interaction_frequency(
        hic_file=args.hic_file,
        genome_table=args.genome_table,
        juicer_tools=args.juicer_tools,
        chromosome=args.chromosome,
        resolution=args.resolution,
        output_bedgraph_file=args.output_bedgraph_file,
        output_significances_file=args.output_significances_file,
        output_fithic_pass1_file=args.output_fithic_pass1_file,
        fdr_threshold=args.fdr_threshold,
    )
    print(output_path)


if __name__ == "__main__":
    try:
        main()
    except (
        FileNotFoundError,
        ValueError,
        RuntimeError,
        subprocess.CalledProcessError,
    ) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
