# /// script
# requires-python = ">=3.10" # Specify the minimum required Python version
# dependencies = [
#   "PyYAML==6.0.2",            # For reading YAML files
#   "polars==1.28.1",            # For data manipulation (DataFrame)
#   "google-genai==1.12.1", # For interacting with the Gemini API
# ]
# ///
#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
validate the single sample metadata of the GEO dataset using the official Gemini API.
This version uses the Google Gemini API Python SDK.
Example1:
python3 ./scripts/geo_metadata_validate_multiple_v3.py \
    --gse_list ./gse_list.txt \
    --output_path ./output.tsv

==============================================

Example2:
python3 ./scripts/geo_metadata_validate_multiple_v3.py \
    --gse_list ./GenAI_validate_geo/geo_metadata_check_rnaseq_unknown_all_250222.tsv \
    --output_path ./geo_metadata_validation_rnaseq_unknown_gemini2flash_250222_output.tsv \
    --error_fix
"""

import re
import os
import sys
import time
import argparse
from pathlib import Path
import yaml
import polars as pl
from google import genai  # Official library from Google for Gemini API
from google.genai import types  # For generation configuration options

def read_gse_list(file_path):
    """Read GSE accession list from file or TSV.
    # Read list of GEO accession IDs from a file.
    """
    if file_path.endswith('.tsv'):
        # For TSV files, read the first column (gse_id)
        with open(file_path, 'r', encoding='utf-8') as f:
            # Skip the header
            next(f)
            gse_ids = [line.split('\t')[0].strip() for line in f if line.strip()]
    else:
        # For normal text files
        with open(file_path, 'r', encoding='utf-8') as f:
            gse_ids = [line.strip() for line in f if line.strip()]
    # Remove duplicate GSE IDs while preserving the order
    seen = set()  # Create an empty set to track seen IDs
    unique_ids = []  # List to store unique IDs in original order
    for gse_id in gse_ids:
        if gse_id not in seen:
            unique_ids.append(gse_id)
            seen.add(gse_id)
    return unique_ids



def find_yaml_file(gse_id, metadata_dir="metadata/metadata_geofetch"):
    """Find YAML file path for given GSE ID.
    # Construct the expected YAML file path and check its existence.
    """
    expected_path = Path(f"{metadata_dir}/{gse_id}/{gse_id}_PEP/{gse_id}_PEP.yaml")
    return expected_path if expected_path.exists() else None



def validate_geo_metadata(client, yaml_file_path, model="gemini-2.0-flash", temperature=0):
    """Validate GEO metadata using Gemini API.
    # Extract metadata and call the official generate_content method.
    """
    try:
        with open(yaml_file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        # Convert backslash+newline and backslash+space to single spaces
        content = content.replace('\\\n', ' ').replace('\\ ', ' ')
        # Remove unnecessary escape characters,
        # but keep those that start with "\x" so that \x99 is preserved for later handling.
        content = re.sub(r'\\(?![ntr"\\x])', '', content)
        yaml_data = yaml.safe_load(content)
    except yaml.YAMLError as e:
        print(f"YAML parsing error in {Path(yaml_file_path).name}: {str(e)[:200]}...")
        return None, None, None
    except (FileNotFoundError, PermissionError, UnicodeDecodeError) as e:
        print(f"File error: {Path(yaml_file_path).name} - {e}")
        return None, None, None

    # Extract relevant information from YAML data
    relevant_info = ""
    if "experiment_metadata" in yaml_data:
        metadata = yaml_data["experiment_metadata"]
        for field in [
            "series_overall_design", 
            "series_title", 
            "series_summary", 
            "series_keywords", 
            "series_platform_organism"
        ]:
            if field in metadata and metadata[field]:
                relevant_info += f"{field}: {metadata[field]}\n"
    if "sample_modifiers" in yaml_data and "append" in yaml_data["sample_modifiers"]:
        relevant_info += "\nsample_modifiers_append:\n"
        for key, value in yaml_data["sample_modifiers"]["append"].items():
            if value:
                relevant_info += f"  {key}: {value}\n"
    if not relevant_info:
        return "The relevant information cannot be extracted from the dataset.", None, None

    # Build the prompt text with instructions and dataset description
    prompt_text = f"""
[Role] You are an expert in analyzing human gene expression data generated via RNA-seq, with a specialization in identifying experimental designs involving controlled heat stress (heat shock).
[Task] Evaluate the following YAML-formatted metadata from Gene Expression Omnibus (GEO), which originates exclusively from human RNA-seq experiments. Determine whether the study involves a controlled heat treatment intervention. Pay close attention to explicit mentions of heat treatment conditions such as temperature, duration, and heat exposure protocols, rather than incidental observations of heat shock protein expression.
[Note1] Even if the dataset includes information about heat shock proteins (HSP), it should be judged as False if the experiment did not involve controlled heat stress (i.e., high temperatures were not actively applied to the subjects).
[Note2] Additionally, please note that the term "Heat Shock Response (HSR)" may also refer to a general cellular stress response, meaning that the stressor may be something other than high temperature.

[Decision Criteria]
- True: Direct evidence of controlled heat stress
- False: Ambient observations or HSP-only references without experimental heat application

[Output Format]
RESULT: true / false (boolean)  // True indicates that the dataset represents a heat stress experiment, False otherwise.
REASON: A brief explanation under 100 words.
KEY_SECTIONS: List the specific sections from the metadata that strongly influenced your judgment, separated by commas.

Dataset description:
{relevant_info}
"""

    try:
        # Configure generation parameters using the official types.GenerateContentConfig
        config = types.GenerateContentConfig(
            max_output_tokens=8192,      # Maximum tokens to generate
            temperature=temperature,     # Deterministic output if set to 0
            top_p=0.95,                  # Nucleus sampling value
            top_k=40,                    # Consider top 40 tokens for sampling
            response_mime_type="text/plain"
        )
        # Request text generation; contents must be a list containing the prompt text
        response = client.models.generate_content(
            model=model,
            contents=[prompt_text],
            config=config
        )
        output_text = response.text  # Retrieve generated text
    except Exception as error:  # pylint: disable=broad-except; allow catching all exceptions intentionally
        # Log the error for the Gemini API call
        print(f"Gemini API call error for {yaml_file_path}: {error}")
        return f"Gemini API call error: {error}", None, None

    # Parse the generated output for RESULT, REASON, and KEY_SECTIONS
    judgment, reason, key_sections = "", "", ""
    for line in output_text.splitlines():
        if line.startswith("RESULT:"):
            judgment = line.replace("RESULT:", "").strip()
        elif line.startswith("REASON:"):
            reason = line.replace("REASON:", "").strip()
        elif line.startswith("KEY_SECTIONS:"):
            key_sections = line.replace("KEY_SECTIONS:", "").strip()
    return judgment, reason, key_sections



def process_multiple_gse(
        client,
        gse_list_path,
        output_path,
        error_fix=False,
        model="gemini-2.0-flash",
        temperature=0
):
    """Process multiple GSE IDs using Gemini API.
    # Loop through each GSE, validate metadata, and store results.
    """
    results = []

    # If error_fix is enabled, only re-process entries that returned a 429 RESOURCE_EXHAUSTED error.
    if error_fix and output_path and os.path.exists(output_path):
        existing_df = pl.read_csv(
            output_path,
            separator='\t',
            infer_schema_length=10000,  # Increase the infer length if necessary
            schema_overrides={"RESULT": pl.Utf8()}  # Override RESULT column to string type
        )
        error_gses = existing_df.filter(
            (pl.col("RESULT") == "ERROR") |
            (pl.col("RESULT").str.contains("429 RESOURCE_EXHAUSTED")) |
            (pl.col("RESULT").str.contains("Gemini API call error:"))
        )["GEO_Accession"].to_list()
        gse_ids = error_gses
        print(f"Error fix mode: Processing {len(gse_ids)} error GSE(s)")
    else:
        gse_ids = read_gse_list(gse_list_path)

    for gse_id in gse_ids:
        yaml_path = find_yaml_file(gse_id)
        if yaml_path is None:
            print(f"Warning: YAML file not found for {gse_id}")
            continue

        judgment, reason, key_sections = validate_geo_metadata(
            client,
            str(yaml_path),
            model,
            temperature
        )
        results.append({
            "GEO_Accession": gse_id,
            "RESULT": judgment if judgment else "ERROR",
            "KEY_SECTIONS": key_sections if key_sections else "",
            "REASON": reason if reason else ""
        })
        print(f"Processed {gse_id}")

        # Wait longer if a resource exhaustion error is detected
        if judgment and "ResourceExhausted" in judgment:
            print(f"Resource exhausted error for {gse_id}. Waiting for 60 seconds.")
            time.sleep(60)
        else:
            time.sleep(30)

    new_df = pl.DataFrame(results)

    # Merge new results with existing output if error_fix mode is enabled.
    if error_fix and output_path and os.path.exists(output_path):
        existing_df = pl.read_csv(
            output_path,
            separator='\t',
            schema_overrides={"RESULT": pl.Utf8()}  # Ensure the RESULT column is read as string
        )
        # Exclude rows that are being reprocessed (i.e., where GEO_Accession is in new_df).
        non_replaced_df = existing_df.filter(
            ~pl.col("GEO_Accession").is_in(new_df["GEO_Accession"].to_list())
        )
        combined_df = pl.concat([non_replaced_df, new_df])
    else:
        combined_df = new_df

    # Ensure unique GEO_Accession entries by keeping the latest result.
    final_df = combined_df.unique(subset=["GEO_Accession"], maintain_order=True)

    return final_df

def main():
    """Main function.
    # Initialize client, process GEO IDs, and save results.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--gse_list", required=True)
    parser.add_argument("--output_path", required=True)
    parser.add_argument("--error_fix", action="store_true", help="Reprocess only ERROR results")
    args = parser.parse_args()

    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Error: GOOGLE_API_KEY is not set. Please set it in your environment variables.")
        sys.exit(1)

    # Initialize the official Gemini API client using your API key
    client = genai.Client(api_key=api_key)

    # process the GSE list
    print(f"Processing {args.gse_list}...")
    df = process_multiple_gse(
        client,
        args.gse_list,
        args.output_path,
        args.error_fix,
        model="gemini-2.0-flash",
        temperature=0
    )
    df.write_csv(args.output_path, separator='\t')
    print(f"Results have been saved to {args.output_path}")

if __name__ == "__main__":
    main()
