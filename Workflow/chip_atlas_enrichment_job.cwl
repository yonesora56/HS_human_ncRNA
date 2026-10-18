#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "ChIP-Atlas enrichment job"
doc: |
  [ChIP-Atlas Enrichment Analysis](https://chip-atlas.org/enrichment_analysis)
  documentation: https://chip-atlas.dbcls.jp/data/manual/Enrichment_Analysis/Enrichment_Analysis.pdf
  Run one ChIP-Atlas Enrichment Analysis job end-to-end:
  submit -> poll until terminal state -> download results.

requirements:
  NetworkAccess:
    networkAccess: true

inputs:
  - id: bed_a
    type: File
    label: "Dataset A BED file"

  - id: bed_b
    type: File
    label: "Dataset B BED file"

  - id: antigen_class
    type:
      type: enum
      symbols:
        - Histone
        - "TFs and others"
        - "RNA polymerase"
        - "ATAC-Seq"
        - "DNase-seq"
        - "Bisulfite-Seq"
        - "Input control"
    label: "antigen class"

  - id: title
    type: string
    label: "job title"

  - id: result_basename
    type: string
    label: "result file basename"
    doc: "Output prefix for downloaded HTML/TSV files"

  - id: desc_a
    type: string
    label: "description A"

  - id: desc_b
    type: string
    label: "description B"

  - id: cell_class
    type: string
    label: "cell type class"
    default: "All cell types"

  - id: threshold
    type:
      type: enum
      symbols:
        - "50"
        - "100"
        - "200"
        - "500"
    label: "MACS2 q-value threshold"
    default: "100"

  - id: genome
    type: string
    label: "genome assembly"
    default: hg38

  - id: sbatch_options
    type: string
    label: "SLURM sbatch options"
    default: "-p epyc -t 180"

  - id: poll_interval
    type: int
    label: "polling interval (seconds)"
    default: 300

  - id: out_dir
    type: string
    label: "download output directory"
    default: results

  - id: formats
    type: string
    label: "download formats"
    default: html,tsv

steps:
  - id: submit
    run: ../Tools/chip_atlas/chip_atlas_enrichment_submit.cwl
    in:
      bed_a: bed_a
      bed_b: bed_b
      antigen_class: antigen_class
      title: title
      result_basename: result_basename
      desc_a: desc_a
      desc_b: desc_b
      cell_class: cell_class
      threshold: threshold
      genome: genome
      sbatch_options: sbatch_options
    out: [request_id, submit_response, submit_log]

  - id: poll
    run: ../Tools/chip_atlas/chip_atlas_status_poll.cwl
    in:
      request_id: submit/request_id
      result_basename: result_basename
      poll_interval: poll_interval
    out: [status_log]

  - id: download
    run: ../Tools/chip_atlas/chip_atlas_download_result.cwl
    in:
      status_log: poll/status_log
      request_id: submit/request_id
      result_basename: result_basename
      out_dir: out_dir
      formats: formats
    out: [result_html, result_tsv, result_zip]

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

  - id: result_html
    type: File?
    label: "result HTML"
    outputSource: download/result_html

  - id: result_tsv
    type: File?
    label: "result TSV"
    outputSource: download/result_tsv

  - id: result_zip
    type: File?
    label: "result ZIP"
    outputSource: download/result_zip

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
