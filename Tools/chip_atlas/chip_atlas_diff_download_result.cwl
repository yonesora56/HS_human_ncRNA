#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "ChIP-Atlas diff analysis download result"
doc: |
  Download ChIP-Atlas Diff Analysis result ZIP and extract wabi_result/
  via scripts/chip_atlas_download_diff_result.sh.
  Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically

  Diff Analysis exposes only zip (no html/tsv). Default behavior extracts
  wabi_result/ and removes the ZIP after extraction.

  help:
    bash scripts/chip_atlas_download_diff_result.sh -h

requirements:
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true

baseCommand: [bash]

arguments:
  - valueFrom: $(inputs.download_script.path)
  - prefix: -o
    valueFrom: $(inputs.out_dir)
  - valueFrom: $(inputs.request_id)
  - valueFrom: $(inputs.result_basename)

inputs:
  - id: download_script
    type: File
    label: "download script"
    doc: "chip_atlas_download_diff_result.sh"
    default:
      class: File
      location: ../../scripts/chip_atlas_download_diff_result.sh

  - id: status_log
    type: File
    label: "status log (dependency only)"
    doc: "Ensures poll completed before download; not passed to the shell script"

  - id: request_id
    type: string
    label: "request ID"
    doc: "wabi requestId for a finished Diff Analysis job"

  - id: result_basename
    type: string
    label: "output subdirectory basename"
    doc: "Output subdirectory name under out_dir (matches chip_atlas_diff_job.sh basename)"

  - id: out_dir
    type: string
    label: "output directory"
    doc: "Root for download/extract inside the job working directory (not the host out/ path)"
    default: results

outputs:
  - id: result_bed
    type: File
    label: "result BED"
    doc: "Differential regions BED (wabi_result.bed)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename)/wabi_result/wabi_result.bed

  - id: result_igv_bed
    type: File
    label: "result IGV BED"
    doc: "IGV-compatible BED (wabi_result.igv.bed)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename)/wabi_result/wabi_result.igv.bed

  - id: result_xml
    type: File
    label: "result XML"
    doc: "Result metadata XML (wabi_result.xml)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename)/wabi_result/wabi_result.xml

  - id: result_log
    type: File
    label: "analysis log"
    doc: "Server-side analysis log (wabi_result.log)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename)/wabi_result/wabi_result.log

  - id: readme
    type: File
    label: "README"
    doc: "Result README (README.md)"
    outputBinding:
      glob: $(inputs.out_dir)/$(inputs.result_basename)/wabi_result/README.md

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
