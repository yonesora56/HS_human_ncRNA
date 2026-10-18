#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "ChIP-Atlas diff analysis job"
doc: |
  Run one ChIP-Atlas Diff Analysis job end-to-end:
  submit -> poll until terminal state -> download and extract wabi_result/.
  Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically

requirements:
  NetworkAccess:
    networkAccess: true

inputs:
  - id: data_a
    type: File
    label: "Dataset A ID list"
    doc: "Plain-text file with one SRX/GSM/DRX/ERX ID or URL row per line (user data)"

  - id: data_b
    type: File
    label: "Dataset B ID list"
    doc: "Plain-text file with one SRX/GSM/DRX/ERX ID or URL row per line (compared data)"

  - id: antigen_class
    type:
      type: enum
      symbols:
        - diffbind
        - dmr
    label: "analysis method"
    doc: "diffbind (DPR) or dmr (DMR)"

  - id: title
    type: string
    label: "job title"

  - id: result_basename
    type: string
    label: "result basename"
    doc: "Prefix for submit/status logs and download subdirectory name"

  - id: desc_a
    type: string
    label: "description A"

  - id: desc_b
    type: string
    label: "description B"

  - id: genome
    type: string
    label: "genome assembly"
    default: hg38

  - id: sbatch_options
    type: string
    label: "SLURM sbatch options"
    default: "-p epyc -t 180"

  - id: skip_preflight
    type: boolean
    label: "skip preflight checks"
    default: false

  - id: url_input
    type: boolean
    label: "URL input mode"
    default: false

  - id: poll_interval
    type: int
    label: "polling interval (seconds)"
    default: 300

  - id: out_dir
    type: string
    label: "download output directory"
    doc: "Root for download/extract inside the job working directory (not the host out/ path)"
    default: results

steps:
  - id: submit
    run: ../Tools/chip_atlas/chip_atlas_diff_submit.cwl
    in:
      data_a: data_a
      data_b: data_b
      antigen_class: antigen_class
      title: title
      result_basename: result_basename
      desc_a: desc_a
      desc_b: desc_b
      genome: genome
      sbatch_options: sbatch_options
      skip_preflight: skip_preflight
      url_input: url_input
    out: [request_id, submit_response, submit_log]

  - id: poll
    run: ../Tools/chip_atlas/chip_atlas_status_poll.cwl
    in:
      request_id: submit/request_id
      result_basename: result_basename
      poll_interval: poll_interval
    out: [status_log]

  - id: download
    run: ../Tools/chip_atlas/chip_atlas_diff_download_result.cwl
    in:
      status_log: poll/status_log
      request_id: submit/request_id
      result_basename: result_basename
      out_dir: out_dir
    out: [result_bed, result_igv_bed, result_xml, result_log, readme]

outputs:
  - id: request_id
    type: string
    label: "request ID"
    outputSource: submit/request_id

  - id: submit_log
    type: File
    label: "submit log"
    outputSource: submit/submit_log

  - id: submit_response
    type: File
    label: "submit response"
    outputSource: submit/submit_response

  - id: status_log
    type: File
    label: "status log"
    outputSource: poll/status_log

  - id: result_bed
    type: File
    label: "result BED"
    outputSource: download/result_bed

  - id: result_igv_bed
    type: File
    label: "result IGV BED"
    outputSource: download/result_igv_bed

  - id: result_xml
    type: File
    label: "result XML"
    outputSource: download/result_xml

  - id: result_log
    type: File
    label: "analysis log"
    outputSource: download/result_log

  - id: readme
    type: File
    label: "README"
    outputSource: download/readme

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
