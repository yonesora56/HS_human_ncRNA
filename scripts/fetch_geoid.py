# /// script
# requires-python = ">=3.8" # Specify the minimum required Python version
# dependencies = [
#   # No external dependencies are used in this script
# ]
# ///
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This script is used to fetch GEO accessions from the GEO summary file using Advanced Search results.
"""


import re
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(
    description="Fetch GEO accessions from the GEO summary file using Advanced Search."
)
parser.add_argument(
    "-f", 
    "--summary_file", 
    type=str,
    required=True,
    help="Path to the GEO summary file e.g. pmc_idlist/geo_use_mesh_result_summary.txt"
)
parser.add_argument(
    "-o", 
    "--output_file", 
    type=str,
    required=True,
    help="Path to the output file e.g. geo_accessions.txt"
)
args = parser.parse_args()

def extract_geo_accessions(summary_file: Path):
    """
    Extract GEO accessions from the GEO summary file.
    """
    # Search for GSE followed by numbers
    pattern = r'Accession:\s+(GSE\d+)'
    # findall() using regex pattern
    found_accessions = re.findall(pattern, summary_file)

    return found_accessions

# read the summary file
with open(Path(args.summary_file), 'r', encoding='utf-8') as file:
    text = file.read()
    accessions = extract_geo_accessions(text)

    # print the number of GEO accessions
    print(f"Found {len(accessions)} GEO accessions")

    # save the GEO accessions to a new file
    OUTPUT_FILE = Path(args.output_file)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as outfile:
        for acc in accessions:
            outfile.write(acc + '\n')

    print(f"GEO accessions are saved in {OUTPUT_FILE}")
