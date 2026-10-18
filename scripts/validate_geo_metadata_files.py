# /// script
# requires-python = ">=3.10" # Specify the minimum required Python version
# dependencies = [
#   "polars==1.28.1",            # For data manipulation (DataFrame)
#   "PyYAML==6.0.2",            # For reading YAML files
# ]
# ///
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This script is used to validate metadata files for GEO accessions.

Overview:
Compare YAML metadata obtained from Geofetch with TSV file metadata
obtained from iSeq and perform preprocessing to pass information to the generative AI.

Usage example:
python3 ./scripts/02_validate_geo_metadata_files.py \
    --gse_list id_list/geo_idlist/gse_accession_list.txt \
    --iseq_dir metadata_iseq/geo_accession_iseq \
    --geofetch_dir metadata_geo \
    --output metadata_validation_results.tsv
"""

import argparse
from pathlib import Path
import polars as pl
import yaml

# Check 1: Check if both TSV and YAML files exist for a given GSE ID
def check_metadata_files(gse_id, iseq_dir, geofetch_dir):
    """Check if both TSV and YAML files exist for a given GSE ID"""
    tsv_path = Path(iseq_dir) / f"{gse_id}_metadata.tsv"
    yaml_path = Path(geofetch_dir) / f"{gse_id}" / f"{gse_id}_PEP" / f"{gse_id}_PEP.yaml"
    soft_path = Path(geofetch_dir) / f"{gse_id}" / f"{gse_id}_GSM.soft"

    status = {
        "gse_id": gse_id,
        "has_tsv": tsv_path.exists(),
        "has_yaml": yaml_path.exists(),
        "has_soft": soft_path.exists(),
        "tsv_path": str(tsv_path) if tsv_path.exists() else None,
        "yaml_path": str(yaml_path) if yaml_path.exists() else None,
        "soft_path": str(soft_path) if soft_path.exists() else None
    }
    return status



# Check 2: Validate library_selection and library_strategy columns
def validate_library_columns(tsv_path):
    """Validate library columns and get additional metadata
    # When reading CSV/TSV files, disable quoting to treat quotes as literal characters
    """
    df = pl.read_csv(
        tsv_path,
        separator='\t',
        quote_char=None,  # Disable quoting to treat quotes as literal characters
        infer_schema=False,
        ignore_errors=True
    )

    try:
        # Check library_selection
        lib_sel_values = df['library_selection'].unique().to_list()
        is_all_cdna = all(val == 'cDNA' for val in lib_sel_values)

        # Check library_strategy
        lib_strat_values = df['library_strategy'].unique().to_list()
        is_all_rnaseq = all(val == 'RNA-Seq' for val in lib_strat_values)

        # Get unique values for each column
        tax_ids = df['tax_id'].unique().to_list()
        lib_layouts = df['library_layout'].unique().to_list()

        # Get first_created value(s)
        first_created = None
        if 'first_created' in df.columns:
            first_created = df['first_created'].unique().to_list()

        return {
            "is_all_cdna": is_all_cdna,
            "lib_sel_values": lib_sel_values if not is_all_cdna else ['cDNA'],
            "is_all_rnaseq": is_all_rnaseq,
            "lib_strat_values": lib_strat_values if not is_all_rnaseq else ['RNA-Seq'],
            "tax_ids": tax_ids,
            "lib_layouts": lib_layouts,
            "first_created": first_created
        }
    except KeyError as e:
        print(f"Missing column in {tsv_path}: {str(e)}")
        return {
            "is_all_cdna": False,
            "lib_sel_values": [],
            "is_all_rnaseq": False,
            "lib_strat_values": [],
            "tax_ids": [],
            "lib_layouts": [],
            "first_created": None
        }

# New function: Check if the YAML file represents a Super series
def check_super_series(yaml_path):
    """Load YAML file and check if it is a 'Super series' by inspecting the 'series_relation' field.
    # Open the YAML file and check if the 'series_relation' field contains "SuperSeries of:"; \
        replace invalid characters
    """
    try:
        # Open file with replacement for invalid characters
        with open(yaml_path, 'r', encoding='utf-8', errors='replace') as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file {yaml_path}: {str(e)}")
        return None
    # Extract experiment metadata; if missing, use an empty dictionary
    experiment_metadata = data.get("experiment_metadata", {})
    series_relation = experiment_metadata.get("series_relation", "")
    # Return True if 'SuperSeries of:' is present in series_relation, otherwise False
    return "SuperSeries of:" in series_relation

# Check if the .soft file indicates heat stress conditions
def check_heat_stress(soft_path):
    """Load .soft file and check if it indicates heat stress conditions based on \
        'Sample_characteristics_ch1' entries.
    # Detect heat stress if any characteristic line contains 'high temperature' \
        or 'heat shock' or 'heat stress' and does not contain 'control'.
    """
    try:
        with open(soft_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except (FileNotFoundError, PermissionError, UnicodeDecodeError) as e:
        print(f"Error reading .soft file {soft_path}: {str(e)}")
        return None
    for line in lines:
        if line.startswith("!Sample_characteristics_ch1"):
            line_lower = line.lower() # convert to lowercase
            # Check for indications of heat stress
            # TODO: Add more heat stress conditions
            if (
                "high temperature" in line_lower or \
                "heat shock" in line_lower or \
                "heat stress" in line_lower or \
                "heatshock" in line_lower or \
                "heatstress" in line_lower or \
                "heat-shock" in line_lower or \
                "heat-stress" in line_lower or \
                "hyperthermia" in line_lower
            ):
                return True
    return False

# New function: Check if the .soft file indicates both heat stress conditions and control conditions
def check_stress_control(soft_path):
    """Load .soft file and check if it indicates both heat stress conditions and \
    control conditions based on '!Sample_characteristics_ch1' entries.
    # Detect if the file contains both stress condition data \
    (e.g. 'high temperature', 'heat shock', 'heat stress', 'heatshock') \
    and control condition data.
    """
    try:
        with open(soft_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except (FileNotFoundError, PermissionError, UnicodeDecodeError) as e:
        print(f"Error reading .soft file {soft_path}: {str(e)}")
        return None
    stress_found = False
    control_found = False
    for line in lines:
        if line.startswith("!Sample_characteristics_ch1"):
            line_lower = line.lower()
            # Check for indications of heat stress
            if ("high temperature" in line_lower or
                "heat shock" in line_lower or 
                "heat stress" in line_lower or 
                "heatshock" in line_lower):
                stress_found = True
            # Check for indication of control condition
            if "control" in line_lower:
                control_found = True
    return {"has_heat_stress": stress_found, "has_control": control_found}

def get_args():
    """Get command line arguments"""
    parser = argparse.ArgumentParser(description="Validate metadata files for GEO accessions")

    parser.add_argument(
        "--gse_list",
        required=True,
        help="Path to the GSE accession list file",
        type=Path
    )

    parser.add_argument(
        "--iseq_dir",
        default="metadata/metadata_iseq",
        help="Directory containing iSeq metadata files",
        type=Path
    )

    parser.add_argument(
        "--geofetch_dir",
        default="metadata/metadata_geofetch",
        help="Directory containing GEOfetch metadata files",
        type=Path
    )

    parser.add_argument(
        "--output",
        required=True,
        help="Output TSV file path",
        type=Path
    )

    args = parser.parse_args()
    return args

def main():
    """
    Validate metadata files for GEO accessions.
    """
    args = get_args()

    # Read GSE list
    with open(args.gse_list, 'r', encoding='utf-8') as f:
        gse_ids = [line.strip() for line in f if line.strip()]

    results = []
    for gse_id in gse_ids:
        print(f"Checking file existence for {gse_id}...")
        status = check_metadata_files(gse_id, args.iseq_dir, args.geofetch_dir)

        if status['has_tsv'] and status['has_yaml']:
            lib_validation = validate_library_columns(status['tsv_path'])
            print(lib_validation)
            # Check for Super series using the YAML metadata
            is_super_series = check_super_series(status['yaml_path'])
            is_heat_stress = check_heat_stress(status['soft_path']) if status['has_soft'] else None
            # Get stress and control indications as a flat dictionary
            stress_control = check_stress_control(status['soft_path']) if status['has_soft'] else {
                "has_heat_stress": None, 
                "has_control": None
            }
            # Format first_created data
            first_created_str = None
            if lib_validation["first_created"] is not None:
                first_created_str = ";".join(map(str, lib_validation["first_created"]))

            results.append({
                "gse_id": gse_id,
                "metadata_status": "complete",
                "lib_sel_values": ";".join(lib_validation["lib_sel_values"]),
                "lib_strat_values": ";".join(lib_validation["lib_strat_values"]),
                "tax_ids": ";".join(map(str, lib_validation["tax_ids"])),
                "lib_layouts": ";".join(lib_validation["lib_layouts"]),
                "first_created": first_created_str,
                "is_all_cdna": lib_validation["is_all_cdna"],
                "is_all_rnaseq": lib_validation["is_all_rnaseq"],
                "is_super_series": is_super_series,
                "inferred_heat_stress": is_heat_stress,
                "has_stress": stress_control["has_heat_stress"],
                "has_control": stress_control["has_control"]
            })
        else:
            results.append({
                "gse_id": gse_id,
                "metadata_status": "incomplete",
                "missing_files": ("tsv" if not status['has_tsv']
                                  else "yaml" if not status['has_yaml']
                                  else "both"),
                "lib_sel_values": None,
                "lib_strat_values": None,
                "tax_ids": None,
                "lib_layouts": None,
                "first_created": None,
                "is_all_cdna": None,
                "is_all_rnaseq": None,
                "is_super_series": None,
                "inferred_heat_stress": None,
                "has_stress": None,
                "has_control": None
            })

    df = pl.DataFrame(results)
    df.write_csv(args.output, separator='\t')
    print(f"Results saved to {args.output}")

if __name__ == "__main__":
    main()
