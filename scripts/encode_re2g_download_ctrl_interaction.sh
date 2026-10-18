#!/bin/bash
# Download ENCODE-rE2G element-gene interaction BED files (ctrl) with wget2.
# The URL list is exported from the ENCODE portal; its first line is the
# metadata query URL, so only "@@download" file URLs are used.
set -e
set -u
set -o pipefail

URL_LIST="${1:-./out/ENCODE_rE2G/ctrl_list/encode_re2g_relationship_bedfile_list_v261004.txt}"
OUT_DIR="${2:-./out/ENCODE_rE2G/ctrl_list/ENCODE-rE2G_ctrl_enhancer_gene_interaction}"
# Keep parallelism low; ENCODE returns 403 when requests are too frequent
THREADS="${THREADS:-2}"
WAIT_SEC="${WAIT_SEC:-2}"

if [ ! -f "${URL_LIST}" ]; then
  echo "ERROR: URL list not found: ${URL_LIST}" >&2
  exit 2
fi

mkdir -p "${OUT_DIR}"

URLS="${OUT_DIR}/download_urls.txt"
grep -E '^https://www\.encodeproject\.org/files/[^/]+/@@download/' "${URL_LIST}" \
  | tr -d '\r' > "${URLS}"
N_URLS="$(wc -l < "${URLS}")"

{
  echo "--- ENCODE-rE2G interaction BED download ---"
  echo "  url_list = ${URL_LIST}"
  echo "  out_dir  = ${OUT_DIR}"
  echo "  n_urls   = ${N_URLS}"
  echo "  threads  = ${THREADS}"
  echo "  wait_sec = ${WAIT_SEC} (randomized)"
  echo "--------------------------------------------"
} >&2

# Call wget2 once per URL. Passing all URLs via --input-file makes wget2
# resolve every ENCODE redirect first, so the signed S3 URLs expire (400)
# before download and the burst of requests triggers 403 from ENCODE.
download_one() {
  local url="$1"
  local out="${OUT_DIR}/$(basename "${url}")"

  if [ -s "${out}" ] && gzip -t "${out}" 2>/dev/null; then
    echo "[skip] $(basename "${url}")"
    return 0
  fi

  # -c resumes partial files left by an interrupted run
  if wget2 \
    --output-document="${out}" \
    --continue \
    --tries=5 \
    --waitretry=60 \
    --timeout=60 \
    --progress=none \
    --quiet \
    "${url}"; then
    echo "[ok]   $(basename "${url}")"
  else
    echo "[fail] $(basename "${url}")"
  fi

  # Randomized pause (0.5x - 1.5x WAIT_SEC) to avoid ENCODE rate limits
  sleep "$(awk -v w="${WAIT_SEC}" 'BEGIN { srand(); printf "%.1f", w * (0.5 + rand()) }')"
}
export -f download_one
export OUT_DIR WAIT_SEC

xargs -P "${THREADS}" -I {} bash -c 'download_one "$1"' _ {} < "${URLS}" \
  || echo "WARN: some downloads returned non-zero status; checking files..." >&2

# Verify every expected file exists and is a valid gzip
FAIL_LOG="${OUT_DIR}/download_fail.txt"
: > "${FAIL_LOG}"
while IFS= read -r url; do
  out="${OUT_DIR}/$(basename "${url}")"
  if [ ! -s "${out}" ] || ! gzip -t "${out}" 2>/dev/null; then
    echo "${url}" >> "${FAIL_LOG}"
  fi
done < "${URLS}"

N_FAIL="$(wc -l < "${FAIL_LOG}")"
{
  echo "Done."
  echo "  expected : ${N_URLS}"
  echo "  ok       : $((N_URLS - N_FAIL))"
  echo "  failed   : ${N_FAIL} (${FAIL_LOG})"
} >&2

if [ "${N_FAIL}" -gt 0 ]; then
  exit 1
fi
