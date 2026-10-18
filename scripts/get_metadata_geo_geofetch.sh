#!/bin/bash

set -e
set -u
set -o pipefail

USAGE="Usage: $0 <geo_id_file> <output_dir_name>

Arguments:
  <geo_id_file>    - e.g. geo_ids.txt
  <output_dir_name> - e.g. metadata_geofetch

Example:
  $0 geo_ids.txt metadata_geofetch"

if [ "$#" -ne 2 ]; then
    echo "$USAGE"
    exit 1
fi

geo_id_file=$1
output_dir_name=$2

if ! command -v geofetch &> /dev/null; then
    echo "Error: geofetch command not found. Please install it first."
    exit 1
fi

if [ ! -f "$geo_id_file" ]; then
    echo "Error: Input file '$geo_id_file' does not exist."
    echo "$USAGE"
    exit 1
fi

# create output directory
output_dir="${output_dir_name}"
mkdir -p "$output_dir"

# prepare file for failed accession numbers
failed_metadata_file="${output_dir}/failed_metadata.txt"
touch "$failed_metadata_file"

# create log directory
log_dir="${output_dir}/logs"
mkdir -p "$log_dir"

# use timestamp for log file name
timestamp=$(date +"%Y%m%d_%H%M%S")
main_log="${log_dir}/geofetch_${timestamp}.log"

echo "Starting. Logs will be saved to ${main_log}."

# log function
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" | tee -a "$main_log"
}

# initialize variables: get total number of GEO IDs
total_ids=$(grep -v '^$' "$geo_id_file" | wc -l)
processed=0

log "Total $total_ids GEO IDs will be processed"

# record start time
start_time=$(date +%s)

# read GEO IDs from file
while read -r accession_number; do
    # skip empty lines
    if [ ! -z "$accession_number" ] && [ -n "$accession_number" ]; then
        # increment
        processed=$((processed+1))
        
        # Check if metadata already exists
        if [ -d "${output_dir}/${accession_number}" ]; then
            log "[$processed/$total_ids] Skipping: metadata for $accession_number already exists"
            continue
        fi
        
        log "[$processed/$total_ids] Processing $accession_number"
        
        # change to sequential processing (remove background processing)
        individual_log="${log_dir}/${accession_number}.log"
        if ! geofetch -i "$accession_number" --metadata-folder "${output_dir}" --just-metadata > "$individual_log" 2>&1; then
            log "Warning: Failed to fetch metadata for $accession_number"
            echo "$accession_number" >> "$failed_metadata_file"
        else
            log "[$processed/$total_ids] $accession_number processing completed"
        fi
    fi
done < "$geo_id_file"

# show statistics after processing
if [ -s "$failed_metadata_file" ]; then
    failed_count=$(wc -l < "$failed_metadata_file")
    success_count=$((total_ids - failed_count))
    log "Processing complete: $success_count succeeded, $failed_count failed out of $total_ids entries"
    log "Failed entries are recorded in: $failed_metadata_file"
else
    log "Processing complete: all $total_ids entries succeeded"
    rm -f "$failed_metadata_file"
fi

# record end time and statistics
end_time=$(date +%s)
elapsed=$((end_time - start_time))
hours=$((elapsed / 3600))
minutes=$(( (elapsed % 3600) / 60 ))
seconds=$((elapsed % 60))

log "Processing time: ${hours} hours ${minutes} minutes ${seconds} seconds"
