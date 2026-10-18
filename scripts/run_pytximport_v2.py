# /// script
# requires-python = ">=3.10" # Specify the minimum required Python version
# dependencies = [
#   "pytximport==0.13.0",
#   "pandas==2.2.3",
#   "pyarrow==20.0.0"
# ]
# ///
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This script is used to run pytximport on a list of quant.sf files
to generate both gene-level and transcript-level count estimates.

Usage:
python3 run_pytximport.py \\
--gtf-file <path_to_gtf_file> \\
--accession-file <path_to_accession_text_file> \\
--quant-dir <path_to_quant_dir> \\
--output-gene-level-file-name <gene_output.tsv> \\
--output-transcript-level-file-name <transcript_output.tsv>
"""

import argparse
import re
from pathlib import Path
import anndata as ad
import numpy as np
import pandas as pd
import xarray as xr
from pytximport import tximport
from pytximport.utils import create_transcript_gene_map_from_annotation

# Strip duplicate disambiguation suffix from Salmon output dirs (e.g. SRR15177495_2 -> SRR15177495)
ACCESSION_DUP_SUFFIX = re.compile(r"^((?:SRR|DRR|ERR|CRR|HRR)\d+)_\d+$")


def normalize_accession_id(dir_name: str) -> str:
    """Normalize Salmon output directory name to metadata accession ID."""
    match = ACCESSION_DUP_SUFFIX.match(dir_name)
    if match:
        return match.group(1)
    return dir_name


def resolve_quant_sf_path(quant_parent_dir: Path, acc_id: str) -> Path | None:
    """Find quant.sf for an accession, including _1, _2, ... duplicate directory names."""
    for candidate in [acc_id, *(f"{acc_id}_{n}" for n in range(1, 10))]:
        quant_sf = quant_parent_dir / candidate / "quant.sf"
        if quant_sf.exists():
            return quant_sf
    return None


def parse_arguments():
    """Parse command line arguments."""

    parser = argparse.ArgumentParser(
        description="Run pytximport to get gene and transcript-level counts from quant.sf files."
    )
    parser.add_argument(
        "--gtf-file",
        required=True,
        type=str,
        help="Path to the GTF file (required for gene-level aggregation)."
    )
    parser.add_argument(
        "--accession-file",
        required=False,  # Changed to optional
        type=str,
        help="Path to the text file containing accession IDs (one per line). \n"
        "If not provided, all quant.sf files under --quant-dir will be used recursively."
    )
    parser.add_argument(
        "--quant-dir",
        required=True,
        type=str,
        help="Path to the parent directory containing subdirectories for each accession ID \n"
        " (e.g., ACC_ID/quant.sf or ACC_ID_1/quant.sf or ACC_ID_2/quant.sf)."
    )
    parser.add_argument(
        "--output-gene-level-file-name",
        default="gene_level_counts.tsv", # Corrected typo and added default
        type=str,
        help="Path to the output TSV file for the gene-level counts matrix \n"
        "(default: gene_level_counts.tsv)."
    )
    parser.add_argument(
        "--output-transcript-level-file-name",
        default="transcript_level_counts.tsv", # Added default
        type=str,
        help="Path to the output TSV file for the transcript-level counts matrix \n"
        "(default: transcript_level_counts.tsv)."
    )
    parser.add_argument(
        "--counts-from-abundance",
        default="scaled_tpm", # default is "scaled_tpm"
        choices=['no','scaled_tpm', 'length_scaled_tpm', 'dtu_scaled_tpm'],
        type=str,
        help="Specify how to calculate counts from abundance for tximport (default: scaled_tpm)."
    )
    parser.add_argument(
        "--ignore-transcript-version",
        action="store_true",
        help="If set, ignore transcript versions (e.g., .1 suffix) \n"
        "when processing transcript-level data. \n"
        "By default, versions are considered."
    )
    parser.add_argument(
        "--gtf-target-field-for-gene-map",
        default="gene_id",
        type=str,
        help="The target field in the GTF attributes to use for gene mapping \n"
        "(e.g., 'gene_id', 'gene_name'). Default is 'gene_id'."
    )

    return parser.parse_args()


def find_quant_sf_files_recursively(quant_parent_dir):
    """
    Recursively find all quant.sf files under the given directory.
    
    Args:
        quant_parent_dir: Path object of the parent directory to search
        
    Returns:
        List of tuples: (accession_id, quant_sf_file_path)
    """
    quant_parent_path = Path(quant_parent_dir)
    quant_files = []

    # Recursively find all quant.sf files
    for quant_sf_path in quant_parent_path.rglob("quant.sf"):
        if quant_sf_path.is_file():
            # Extract accession ID from the parent directory name
            # Assuming the structure is: .../accession_id/quant.sf
            acc_id = normalize_accession_id(quant_sf_path.parent.name)
            quant_files.append((acc_id, str(quant_sf_path)))

    return quant_files


def main():
    """Main function to execute the script."""
    args = parse_arguments()

    quant_parent_dir = Path(args.quant_dir)

    # Check if accession file is provided
    if args.accession_file:
        # Original behavior: use accession file
        print("Using accession file to locate quant.sf files...")
        try:
            with open(args.accession_file, "r", encoding="utf-8") as f:
                accession_ids = [line.strip() for line in f if line.strip()]
        except FileNotFoundError:
            print(f"Error: Accession file not found at '{args.accession_file}'")
            return
        except (UnicodeDecodeError, OSError) as e:
            print(f"Error reading accession file '{args.accession_file}': {e}")
            return

        if not accession_ids:
            print("No accession IDs found in the provided file. Exiting.")
            return

        # Construct the list of quant.sf file paths
        quant_sf_files = []
        missing_files_count = 0
        for acc_id in accession_ids:
            quant_sf_path = resolve_quant_sf_path(quant_parent_dir, acc_id)
            if quant_sf_path is not None:
                quant_sf_files.append(str(quant_sf_path))
            else:
                print(
                    f"Warning: quant.sf not found for {acc_id} under '{quant_parent_dir}' "
                    f"(checked {acc_id} and {acc_id}_1..{acc_id}_9)"
                )
                missing_files_count += 1
        if not quant_sf_files:
            print("No quant.sf files were found. \n"
                  "Please check the paths and accession IDs. \n"
                  "Exiting.")
            return

        if missing_files_count > 0:
            print(
                (
                    f"Warning: Proceeding with {len(quant_sf_files)} found quant.sf files out of "
                    f"{len(accession_ids)} accession IDs. "
                    f"Missing {missing_files_count} quant.sf files."
                )
            )
    else:
        # New behavior: recursively find all quant.sf files
        print(f"Recursively searching for all quant.sf files under '{quant_parent_dir}'...")
        found_files = find_quant_sf_files_recursively(quant_parent_dir)
        if not found_files:
            print(f"No quant.sf files were found under '{quant_parent_dir}'. Exiting.")
            return

        print(f"Found {len(found_files)} quant.sf files:")
        for acc_id, file_path in found_files:
            print(f"  - {acc_id}: {file_path}")

        # Extract just the file paths
        quant_sf_files = [file_path for _, file_path in found_files]


    print(f"Processing {len(quant_sf_files)} quant.sf files...")

    # --- Gene-level processing ---
    if args.gtf_file:
        print("\n--- Starting Gene-Level Quantification ---")
        try:
            print(
                (
                    f"Creating transcript-to-gene map from GTF: "
                    f"{args.gtf_file} using target field: "
                    f"{args.gtf_target_field_for_gene_map}"
                )
            )
            transcript_gene_map = create_transcript_gene_map_from_annotation(
                args.gtf_file,
                target_field=args.gtf_target_field_for_gene_map
            )
            print("Transcript-to-gene map created successfully.")
        except (ValueError, RuntimeError, OSError) as e:
            print(f"Error creating transcript-to-gene map from GTF: {e}")
            return # Exit if map creation fails

        try:
            txi_gene = tximport(
              quant_sf_files,
              "salmon",
              transcript_gene_map=transcript_gene_map,
              counts_from_abundance=args.counts_from_abundance,
              output_type="xarray",
              ignore_transcript_version=True # Typically ignore version for gene sum
            )
        except (ValueError, RuntimeError, OSError) as e:
            print(f"Error during gene-level tximport processing: {e}")
            return

        # output_type="xarray" is a runtime choice; the type stub still returns a union.
        if not isinstance(txi_gene, xr.Dataset):
            print(
                "Error: expected an xarray Dataset from gene-level tximport, "
                f"got {type(txi_gene).__name__}."
            )
            return

        # Save the gene-level data
        try:
            gene_column_names = [
                normalize_accession_id(Path(fp).parent.name)
                for fp in txi_gene.coords["file_path"].data
            ]
            df_gene_counts = pd.DataFrame(
                txi_gene["counts"].data,
                index=txi_gene.coords["gene_id"].data,
                columns=pd.Index(gene_column_names),
            )
            # Use the field as index name
            df_gene_counts.index.name = args.gtf_target_field_for_gene_map
            df_gene_counts.to_csv(args.output_gene_level_file_name, sep="\t")
            print(f"Gene counts successfully saved to '{args.output_gene_level_file_name}'")
        except (KeyError, ValueError, OSError) as e:
            print(f"Error creating or saving gene-level DataFrame: {e}")
    else:
        print("Skipping gene-level quantification as no GTF file was provided.")


    # --- Transcript-level processing ---
    print("\n--- Starting Transcript-Level Quantification ---")
    try:
        txi_transcript = tximport(
            quant_sf_files,
            "salmon",
            counts_from_abundance=args.counts_from_abundance,
            return_transcript_data=True,
            ignore_transcript_version=args.ignore_transcript_version
        )
    except (ValueError, RuntimeError, OSError) as e:
        print(f"Error during transcript-level tximport processing: {e}")
        return

    # Default output_type is AnnData; the type stub still returns a union.
    if not isinstance(txi_transcript, ad.AnnData) or txi_transcript.X is None:
        print(
            "Error: expected AnnData with a counts matrix from transcript-level tximport, "
            f"got {type(txi_transcript).__name__}."
        )
        return

    # Save the transcript-level data
    try:
        transcript_column_names = [
            normalize_accession_id(Path(fp).parent.name) for fp in txi_transcript.obs_names
        ]
        df_transcript_counts = pd.DataFrame(
            data=np.asarray(txi_transcript.X).T,
            index=txi_transcript.var_names,
            columns=pd.Index(transcript_column_names),
        )
        df_transcript_counts.index.name = "transcript_id"
        df_transcript_counts.to_csv(args.output_transcript_level_file_name, sep="\t")
        print(f"Transcript counts successfully saved to '{args.output_transcript_level_file_name}'")
    except (KeyError, ValueError, OSError) as e:
        print(f"Error creating or saving transcript-level DataFrame: {e}")

    print("\nScript finished.")


if __name__ == "__main__":
    main()
