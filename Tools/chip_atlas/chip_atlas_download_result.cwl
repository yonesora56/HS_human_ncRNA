#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "ChIP-Atlas download result"
doc: |
  Download ChIP-Atlas Enrichment Analysis result files (HTML / TSV / ZIP)
  via scripts/chip_atlas_download_result.sh.

requirements:
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true

baseCommand: [bash]

arguments:
  - valueFrom: $(inputs.download_script.path)
  - prefix: -o
    valueFrom: $(inputs.out_dir)
  - prefix: -f
    valueFrom: $(inputs.formats)
  - valueFrom: $(inputs.request_id)
  - valueFrom: $(inputs.result_basename)

inputs:
  - id: download_script
    type: File
    label: "download script"
    doc: "chip_atlas_download_result.sh"
    default:
      class: File
      location: ../../scripts/chip_atlas_download_result.sh

  - id: status_log
    type: File
    label: "status log (dependency only)"
    doc: "Ensures poll completed before download; not passed to the shell script"

  - id: request_id
    type: string
    label: "request ID"
    doc: "wabi requestId for a finished job"

  - id: result_basename
    type: string
    label: "output file basename"
    doc: "Output file prefix without extension"

  - id: out_dir
    type: string
    label: "output directory"
    doc: "Directory for downloaded result files (relative to job working directory)"
    default: results

  - id: formats
    type: string
    label: "download formats"
    doc: "Comma-separated formats: html, tsv, zip"
    default: html,tsv

outputs:
  - id: result_html
    type: File?
    label: "result HTML"
    doc: "Enrichment analysis HTML report"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename).html

  - id: result_tsv
    type: File?
    label: "result TSV"
    doc: "Enrichment analysis TSV table"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename).tsv

  - id: result_zip
    type: File?
    label: "result ZIP"
    doc: "Enrichment analysis ZIP archive (when requested via formats)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename).zip

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
