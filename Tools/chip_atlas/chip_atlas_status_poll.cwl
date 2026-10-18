#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "ChIP-Atlas status poll"
doc: |
  Poll a ChIP-Atlas wabi job until a terminal state (finished or not-found)
  via scripts/chip_atlas_status_log.sh (-p mode).

  Shared by Enrichment and Diff Analysis workflows (same wabi endpoint and
  terminal states). Reuse this tool after chip_atlas_enrichment_submit.cwl
  or chip_atlas_diff_submit.cwl.

requirements:
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true

baseCommand: bash

arguments:
  - valueFrom: $(inputs.poll_script.path)
  - "-p"
  - prefix: -i
    valueFrom: $(inputs.poll_interval)
  - prefix: -o
    valueFrom: $(inputs.result_basename)_statuslog.txt
  - valueFrom: $(inputs.request_id)

inputs:
  - id: poll_script
    type: File
    label: "poll script"
    doc: "chip_atlas_status_log.sh"
    default:
      class: File
      location: ../../scripts/chip_atlas_status_log.sh

  - id: request_id
    type: string
    label: "request ID"
    doc: "wabi requestId returned by a ChIP-Atlas submit step (enrichment or diff)"

  - id: result_basename
    type: string
    label: "result file basename"
    doc: "Prefix for status log output file (e.g. foo_statuslog.txt)"

  - id: poll_interval
    type: int
    label: "polling interval (seconds)"
    doc: "Seconds between status queries in polling mode"
    default: 300

outputs:
  - id: status_log
    type: File
    label: "status log"
    doc: "Timestamped append-only status snapshots"
    outputBinding:
      glob: $(inputs.result_basename)_statuslog.txt

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
