#!/bin/bash
# Download files for MassIVE dataset MSV000090634 (PXD037887).
# Skips files that already exist locally unless --force is given.
#
# Default method "auto" tries curl first, then lftp on failure.
# MassIVE FTPS is flaky: curl may hit error 56, lftp may hit 530.
set -euo pipefail

MSV_ID="MSV000090634"
FTP_PARTITION="v05"
FTP_HOST="massive-ftp.ucsd.edu"
HTTPS_BASE="https://massive.ucsd.edu/ProteoSAFe/DownloadResultFile"
OUT_DIR="./Data/proteomics/MSV000090634"
METHOD="auto"
SLEEP_SEC=120
RETRIES=3
RETRY_SLEEP=30
FORCE=false
DRY_RUN=false
COLLECTION="all"

# All 13 files listed on the MassIVE dataset page.
FILES=(
  "ccms_parameters/params.xml"
  "ccms_quant/summary.tsv"
  "quant/20220804_153805_Granules_ahuv_MSstats_Report.xls"
  "raw/00002068___P_arsenite_rep1.raw"
  "raw/00002069___P_arsenite_rep2.raw"
  "raw/00002070___P_arsenite_rep3.raw"
  "raw/00002071___P_heat_rep1.raw"
  "raw/00002072___P_heat_rep2.raw"
  "raw/00002073___P_heat_rep3.raw"
  "raw/00002077___P_4sU_UVA_rep1.raw"
  "raw/00002078___P_4sU_UVA_rep2.raw"
  "raw/00002079___P_4sU_UVA_rep3.raw"
  "search/20220804_153805_Granules_ahuv_MSstats_Report.xls"
)

usage() {
  cat <<EOF
Usage: $0 [options] [command]

Download missing files for MassIVE ${MSV_ID}.

Commands:
  download   Download files (default)
  browse     List remote FTPS directory contents
  list       Show local download status for all known files

Options:
  -o <dir>         Output directory (default: ${OUT_DIR})
  -m <method>      Download method: auto | curl | lftp | https (default: auto)
  -c <collection>  Download only this collection: all | raw | quant | search | ccms_parameters | ccms_quant
  -s <sec>         Sleep seconds between HTTPS downloads (default: ${SLEEP_SEC})
  -r <n>           Retry count for FTPS downloads (default: ${RETRIES})
  -f               Re-download even if the local file already exists
  -n               Dry run (show what would be downloaded)
  -h               Show this help and exit

Examples:
  $0 browse
  $0 list
  $0 -c raw download
  $0 -m lftp -c quant download
  $0 -m https -s 180 download
  $0 -n -c quant download

FTPS browse (interactive):
  lftp -u anonymous, ftp://${FTP_HOST}
  > set ftp:ssl-force true
  > set ssl:verify-certificate no
  > cls -l ${FTP_PARTITION}/${MSV_ID}/
  > cls -l ${FTP_PARTITION}/${MSV_ID}/raw/
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

urlencode_file_path() {
  python3 - "$1" <<'PY'
import sys
import urllib.parse

print(urllib.parse.quote(sys.argv[1], safe=""))
PY
}

collection_of() {
  printf '%s\n' "$1" | cut -d/ -f1
}

should_download() {
  local rel_path="$1"
  local collection
  collection="$(collection_of "$rel_path")"

  if [[ "$COLLECTION" != "all" && "$collection" != "$COLLECTION" ]]; then
    return 1
  fi
  return 0
}

local_path_for() {
  printf '%s/%s\n' "$OUT_DIR" "$1"
}

file_exists_locally() {
  local local_path
  local_path="$(local_path_for "$1")"
  [[ -s "$local_path" ]]
}

browse_remote() {
  require_cmd lftp
  log "Listing ftps://${FTP_HOST}/${FTP_PARTITION}/${MSV_ID}/"
  lftp -c "
    set ftp:ssl-force true
    set ssl:verify-certificate no
    set net:timeout 60
    open -u anonymous, ftp://${FTP_HOST}
    echo '=== top level ==='
    cls -l ${FTP_PARTITION}/${MSV_ID}/
    echo
    echo '=== raw/ ==='
    cls -l ${FTP_PARTITION}/${MSV_ID}/raw/
    echo
    echo '=== quant/ ==='
    cls -l ${FTP_PARTITION}/${MSV_ID}/quant/
    echo
    echo '=== search/ ==='
    cls -l ${FTP_PARTITION}/${MSV_ID}/search/
    quit
  "
}

list_status() {
  local rel_path local_path status
  printf '%-12s  %-55s  %s\n' "COLLECTION" "FILE" "STATUS"
  for rel_path in "${FILES[@]}"; do
    local_path="$(local_path_for "$rel_path")"
    if [[ -f "$local_path" && ! -s "$local_path" ]]; then
      status="empty/incomplete (re-download with --force or rerun)"
    elif [[ -f "$local_path" ]]; then
      status="present ($(du -h "$local_path" | awk '{print $1}'))"
    else
      status="missing"
    fi
    printf '%-12s  %-55s  %s\n' "$(collection_of "$rel_path")" "$rel_path" "$status"
  done
}

download_with_curl() {
  local rel_path="$1"
  local local_path remote_url
  local_path="$(local_path_for "$rel_path")"
  mkdir -p "$(dirname "$local_path")"
  remote_url="ftp://${FTP_HOST}/${FTP_PARTITION}/${MSV_ID}/${rel_path}"

  if $DRY_RUN; then
    log "[dry-run] curl ${remote_url} -> ${local_path}"
    return 0
  fi

  log "Downloading via FTPS (curl): ${rel_path}"
  curl --ftp-ssl-control --ssl-reqd --insecure \
    --user 'anonymous:' \
    --continue-at - \
    --fail --show-error --location \
    --output "$local_path" \
    "$remote_url"
}

download_with_lftp() {
  local rel_path="$1"
  local local_path attempt
  local_path="$(local_path_for "$rel_path")"
  mkdir -p "$(dirname "$local_path")"

  if $DRY_RUN; then
    log "[dry-run] lftp get ${FTP_PARTITION}/${MSV_ID}/${rel_path} -> ${local_path}"
    return 0
  fi

  for ((attempt = 1; attempt <= RETRIES; attempt++)); do
    log "Downloading via FTPS (lftp): ${rel_path} (attempt ${attempt}/${RETRIES})"
    if lftp -c "
      set ftp:ssl-force true
      set ssl:verify-certificate no
      set net:timeout 120
      set net:max-retries 5
      set net:reconnect-interval-base 5
      open -u anonymous, ftp://${FTP_HOST}
      get -c ${FTP_PARTITION}/${MSV_ID}/${rel_path} -o ${local_path}
      quit
    "; then
      return 0
    fi
    if (( attempt < RETRIES )); then
      log "Retrying in ${RETRY_SLEEP}s (MassIVE anonymous login can be busy)"
      sleep "$RETRY_SLEEP"
    fi
  done

  echo "Error: lftp failed after ${RETRIES} attempts: ${rel_path}" >&2
  return 1
}

download_one_file() {
  local rel_path="$1"

  case "$METHOD" in
    curl) download_with_curl "$rel_path" ;;
    lftp) download_with_lftp "$rel_path" ;;
    https) download_with_https "$rel_path" ;;
    auto)
      if download_with_curl "$rel_path"; then
        return 0
      fi
      log "curl failed; falling back to lftp for ${rel_path}"
      download_with_lftp "$rel_path"
      ;;
    *)
      echo "Error: unknown method: $METHOD (use auto, curl, lftp, or https)" >&2
      exit 1
      ;;
  esac
}

download_with_https() {
  local rel_path="$1"
  local local_path encoded remote_file url
  local_path="$(local_path_for "$rel_path")"
  mkdir -p "$(dirname "$local_path")"
  remote_file="f.${MSV_ID}/${rel_path}"
  encoded="$(urlencode_file_path "$remote_file")"
  url="${HTTPS_BASE}?file=${encoded}&forceDownload=true"

  if $DRY_RUN; then
    log "[dry-run] wget ${url} -> ${local_path}"
    return 0
  fi

  log "Downloading via HTTPS: ${rel_path}"
  wget -c --no-check-certificate -O "$local_path" "$url"
  log "Sleeping ${SLEEP_SEC}s to avoid HTTP 429"
  sleep "$SLEEP_SEC"
}

download_files() {
  local rel_path

  case "$METHOD" in
    auto)
      require_cmd curl
      require_cmd lftp
      ;;
    curl)
      require_cmd curl
      ;;
    lftp)
      require_cmd lftp
      ;;
    https)
      require_cmd wget
      require_cmd python3
      ;;
    *)
      echo "Error: unknown method: $METHOD (use auto, curl, lftp, or https)" >&2
      exit 1
      ;;
  esac

  mkdir -p "$OUT_DIR"

  for rel_path in "${FILES[@]}"; do
    if ! should_download "$rel_path"; then
      continue
    fi

    if file_exists_locally "$rel_path" && ! $FORCE; then
      log "Skip existing file: ${rel_path}"
      continue
    fi

    download_one_file "$rel_path"
  done
}

COMMAND="download"

while getopts ":o:m:c:s:r:fnh" opt; do
  case "$opt" in
    o) OUT_DIR="$OPTARG" ;;
    m) METHOD="$OPTARG" ;;
    c) COLLECTION="$OPTARG" ;;
    s) SLEEP_SEC="$OPTARG" ;;
    r) RETRIES="$OPTARG" ;;
    f) FORCE=true ;;
    n) DRY_RUN=true ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -gt 0 ]]; then
  COMMAND="$1"
fi

case "$COMMAND" in
  download) download_files ;;
  browse) browse_remote ;;
  list) list_status ;;
  *)
    echo "Error: unknown command: $COMMAND" >&2
    usage >&2
    exit 1
    ;;
esac
