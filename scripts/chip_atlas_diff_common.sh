#!/bin/bash
# Shared helpers for ChIP-Atlas Diff Analysis shell scripts.
# Source this file; do not execute directly.

CHIP_ATLAS_DATA_BASE="https://chip-atlas.dbcls.jp/data"
CHIP_ATLAS_META_BASE="https://chip-atlas.dbcls.jp/data/metadata"
EXPERIMENT_LIST_CACHE="${CHIP_ATLAS_DIFF_EXPERIMENT_LIST_CACHE:-./out/chipatlas/experimentList.tab}"

# Map Diff Analysis threshold (50/100/...) to peak BED directory suffix (05/10/20).
chip_atlas_diff_bed_tag() {
  local t="$1"
  case "${t}" in
    50|5|05|1e-5|1e-05) printf '05' ;;
    100|10|1e-10|1.0e-10) printf '10' ;;
    200|20|1e-20|1.0e-20) printf '20' ;;
    999) printf '05' ;;
    *)
      echo "ERROR: unsupported diffbind threshold '${t}' (use 50, 100, or 200)" >&2
      return 1
      ;;
  esac
}

# Normalize an ID list: strip CR, drop blanks/comments, ensure trailing newline.
chip_atlas_diff_normalize_id_file() {
  local src="$1" dst="$2"
  grep -v '^[[:space:]]*$' "${src}" \
    | grep -v '^[[:space:]]*#' \
    | tr -d '\r' \
    > "${dst}"
  if [ ! -s "${dst}" ]; then
    echo "ERROR: ${src} has no usable lines after normalization" >&2
    return 1
  fi
  printf '\n' >> "${dst}"
}

# Return 0 when the line looks like an accession ID or a Diff Analysis URL row.
chip_atlas_diff_line_kind() {
  local line="$1"
  if [[ "${line}" =~ ^https?:// ]]; then
    printf 'url'
  elif [[ "${line}" =~ ^(SRX|DRX|ERX|GSM)[0-9]+$ ]]; then
    printf 'id'
  else
    printf 'bad'
  fi
}

chip_atlas_diff_fetch_experiment_list() {
  local cache_dir
  cache_dir="$(dirname "${EXPERIMENT_LIST_CACHE}")"
  mkdir -p "${cache_dir}"
  if [ ! -s "${EXPERIMENT_LIST_CACHE}" ]; then
    echo "Fetching experimentList.tab -> ${EXPERIMENT_LIST_CACHE}" >&2
    curl -fsSL "${CHIP_ATLAS_META_BASE}/experimentList.tab" -o "${EXPERIMENT_LIST_CACHE}"
  fi
}

# Look up mapped read count (first field of readInfo) for expid+genome.
chip_atlas_diff_lookup_reads() {
  local expid="$1" genome="$2"
  chip_atlas_diff_fetch_experiment_list
  awk -F'\t' -v id="${expid}" -v gb="${genome}" '
    $1 == id && $2 == gb { print $8; exit }
  ' "${EXPERIMENT_LIST_CACHE}" | awk -F',' '{ print $1; exit }'
}

chip_atlas_diff_http_ok() {
  local url="$1"
  local code
  # HEAD only: some peak BED files are ~1MB and exceed 20s on full GET
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -I "${url}")"
  [ "${code}" = "200" ]
}

# Build a URL-format line for diffbind from one SRX/GSM-like ID.
chip_atlas_diff_url_line_diffbind() {
  local expid="$1" genome="$2" bed_tag="$3"
  local reads bw bed
  reads="$(chip_atlas_diff_lookup_reads "${expid}" "${genome}")"
  if [ -z "${reads}" ]; then
    echo "ERROR: mapped read count not found for ${expid} (${genome}) in experimentList.tab" >&2
    return 1
  fi
  bw="${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bw/${expid}.bw"
  bed="${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bed${bed_tag}/${expid}.${bed_tag}.bed"
  printf '%s\t%s\t%s' "${bw}" "${bed}" "${reads}"
}

# Build a URL-format line for dmr (Bisulfite-seq methylation bigWig only).
chip_atlas_diff_url_line_dmr() {
  local expid="$1" genome="$2"
  printf '%s' "${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bs/methyl/${expid}.methyl.bw"
}

# Convert an accession ID list to Diff Analysis URL rows.
chip_atlas_diff_convert_to_url_file() {
  local src="$1" dst="$2" genome="$3" antigen_class="$4" threshold="$5"
  local bed_tag="" line kind
  if [ "${antigen_class}" = "diffbind" ]; then
    bed_tag="$(chip_atlas_diff_bed_tag "${threshold}")"
  fi
  : > "${dst}"
  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line//$'\r'/}"
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    kind="$(chip_atlas_diff_line_kind "${line}")"
    case "${kind}" in
      url) printf '%s\n' "${line}" >> "${dst}" ;;
      id)
        if [ "${antigen_class}" = "diffbind" ]; then
          chip_atlas_diff_url_line_diffbind "${line}" "${genome}" "${bed_tag}" >> "${dst}" \
            || return 1
        else
          chip_atlas_diff_url_line_dmr "${line}" "${genome}" >> "${dst}" \
            || return 1
        fi
        printf '\n' >> "${dst}"
        ;;
      *)
        echo "ERROR: cannot convert line to URL input: ${line}" >&2
        return 1
        ;;
    esac
  done < "${src}"
}

# Preflight one ID list. Sets global PREFLIGHT_FAIL=1 on hard failures.
chip_atlas_diff_preflight_file() {
  local label="$1" f="$2" genome="$3" antigen_class="$4" threshold="$5"
  local bed_tag="" line kind url_a url_b url_c reads

  if [ "${antigen_class}" = "diffbind" ]; then
    bed_tag="$(chip_atlas_diff_bed_tag "${threshold}")"
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line//$'\r'/}"
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac

    kind="$(chip_atlas_diff_line_kind "${line}")"
    case "${kind}" in
      id)
        if [ "${antigen_class}" = "diffbind" ]; then
          url_a="${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bw/${line}.bw"
          url_b="${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bed${bed_tag}/${line}.${bed_tag}.bed"
          reads="$(chip_atlas_diff_lookup_reads "${line}" "${genome}")"
          if [ -z "${reads}" ]; then
            echo "ERROR: ${label}: ${line} not found in experimentList.tab for genome ${genome}" >&2
            PREFLIGHT_FAIL=1
            continue
          fi
          if ! chip_atlas_diff_http_ok "${url_a}"; then
            echo "ERROR: ${label}: missing bigWig for ${line}: ${url_a}" >&2
            PREFLIGHT_FAIL=1
          fi
          if ! chip_atlas_diff_http_ok "${url_b}"; then
            echo "ERROR: ${label}: missing peak BED for ${line}: ${url_b}" >&2
            PREFLIGHT_FAIL=1
          fi
        else
          url_a="${CHIP_ATLAS_DATA_BASE}/${genome}/eachData/bs/methyl/${line}.methyl.bw"
          if ! chip_atlas_diff_http_ok "${url_a}"; then
            echo "ERROR: ${label}: missing methyl bigWig for ${line}: ${url_a}" >&2
            PREFLIGHT_FAIL=1
          fi
        fi
        ;;
      url)
        if [ "${antigen_class}" = "diffbind" ]; then
          url_a="$(printf '%s' "${line}" | awk -F'\t' '{ print $1 }')"
          url_b="$(printf '%s' "${line}" | awk -F'\t' '{ print $2 }')"
          url_c="$(printf '%s' "${line}" | awk -F'\t' '{ print $3 }')"
          if [ -z "${url_a}" ] || [ -z "${url_b}" ] || [ -z "${url_c}" ]; then
            echo "ERROR: ${label}: URL row must be: bigWig<TAB>bed<TAB>mapped_reads" >&2
            echo "       got: ${line}" >&2
            PREFLIGHT_FAIL=1
            continue
          fi
          chip_atlas_diff_http_ok "${url_a}" || {
            echo "ERROR: ${label}: bigWig not reachable: ${url_a}" >&2
            PREFLIGHT_FAIL=1
          }
          chip_atlas_diff_http_ok "${url_b}" || {
            echo "ERROR: ${label}: BED not reachable: ${url_b}" >&2
            PREFLIGHT_FAIL=1
          }
        else
          url_a="$(printf '%s' "${line}" | awk '{ print $1 }')"
          chip_atlas_diff_http_ok "${url_a}" || {
            echo "ERROR: ${label}: methyl bigWig not reachable: ${url_a}" >&2
            PREFLIGHT_FAIL=1
          }
        fi
        ;;
      *)
        echo "ERROR: ${label}: invalid line (expect SRX/GSM/DRX/ERX ID or http URL row): ${line}" >&2
        PREFLIGHT_FAIL=1
        ;;
    esac
  done < "${f}"
}
