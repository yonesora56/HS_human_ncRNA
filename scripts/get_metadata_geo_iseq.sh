#!/bin/zsh

# arguments
input_file=$1
output_dir_name=$2

if [ -z "$input_file" ]; then
    echo "Usage: $0 <input_file> <output_dir_name>"
    exit 1
fi

# create output directory
output_dir="${output_dir_name}"
mkdir -p "$output_dir"

# prepare csv file for failed accession numbers
failed_metadata_file="${output_dir}/failed_metadata.csv"
echo "gse_id" > "$failed_metadata_file"

# read input file and process each GSE ID
while read -r gse_id || [ -n "$gse_id" ]; do
    # skip empty lines
    if [ -z "$gse_id" ]; then
        continue
    fi
    
    # trim whitespace from GSE ID
    gse_id=$(echo "$gse_id" | tr -d '[:space:]')
    
    # check if output file already exists
    if [ -f "${output_dir}/${gse_id}_metadata.tsv" ] || [ -f "${output_dir}/${gse_id}_metadata.csv" ]; then
        echo "Skipping $gse_id: metadata file already exists"
        continue
    fi
    
    echo "Retrieving metadata for $gse_id..."
    
    # run iseq command
    docker run --rm \
        --platform linux/amd64 \
        -v $(pwd):/work \
        -w /work \
        -e TERM=xterm \
        quay.io/biocontainers/iseq:1.9.1--hdfd78af_0 \
        iseq -i "$gse_id" -m

    # remove unnecessary xlsx file (check in current directory)
    if [ -f "${gse_id}.metadata.xlsx" ]; then
        rm -f "${gse_id}.metadata.xlsx"
    fi

    # Define source and target file paths
    source_tsv="${gse_id}.metadata.tsv" # Check in current directory
    source_csv="${gse_id}.metadata.csv" # Check in current directory
    output_tsv="${output_dir}/${gse_id}_metadata.tsv"
    output_csv="${output_dir}/${gse_id}_metadata.csv"

    # check if iseq output file exists in the current directory and move it
    if [ -f "$source_tsv" ]; then
        echo "Found TSV file: $source_tsv"
        mv -v "$source_tsv" "$output_tsv" # Move from current dir to output dir
        if [ $? -eq 0 ]; then # Check if move was successful
             echo "Metadata saved to $output_tsv"
        else
             echo "Error moving $source_tsv to $output_tsv"
             echo "$gse_id" >> "$failed_metadata_file"
             echo "Added to failed metadata list: $failed_metadata_file"
        fi
    elif [ -f "$source_csv" ]; then
        echo "Found CSV file: $source_csv"
        mv -v "$source_csv" "$output_csv" # Move from current dir to output dir
        if [ $? -eq 0 ]; then # Check if move was successful
             echo "Metadata saved to $output_csv"
        else
             echo "Error moving $source_csv to $output_csv"
             echo "$gse_id" >> "$failed_metadata_file"
             echo "Added to failed metadata list: $failed_metadata_file"
        fi
    else
        # This block now correctly indicates that iseq failed to produce output in the current directory
        echo "Warning: No metadata file found for $gse_id in the current directory after running iseq."
        echo "$gse_id" >> "$failed_metadata_file"
        echo "Added to failed metadata list: $failed_metadata_file"
    fi
    
    # Add small delay between requests
    sleep 2
    
done < "$input_file"

# show statistics after processing
if [ -f "$failed_metadata_file" ]; then
    failed_count=$(( $(wc -l < "$failed_metadata_file") - 1 ))
    if [ $failed_count -gt 0 ]; then
        echo "Processing complete with $failed_count failed metadata retrievals"
        echo "Failed entries are recorded in: $failed_metadata_file"
    else
        rm "$failed_metadata_file"
        echo "Processing complete with no failed metadata retrievals"
    fi
fi