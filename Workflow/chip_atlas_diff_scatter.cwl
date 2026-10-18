#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "ChIP-Atlas diff analysis scatter"
doc: |
  Submit, poll, and download ChIP-Atlas Diff Analysis jobs in parallel via
  scatter over matching input arrays (one job per dataset pair).
  Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  NetworkAccess:
    networkAccess: true

inputs:
  - id: data_a_files
    type: File[]
    label: "Dataset A ID lists"
    doc: "One SRX/GSM ID list file per scatter job (user data)"

  - id: data_b_files
    type: File[]
    label: "Dataset B ID lists"
    doc: "One SRX/GSM ID list file per scatter job (compared data)"

  - id: antigen_classes
    type:
      type: array
      items:
        type: enum
        symbols:
          - diffbind
          - dmr
    label: "analysis methods"
    doc: "One antigenClass (diffbind or dmr) per scatter job"

  - id: job_titles
    type: string[]
    label: "job titles"
    doc: "One job title per scatter job (same length as data_a_files)"

  - id: result_basenames
    type: string[]
    label: "result basenames"
    doc: "One download basename per scatter job (same length as data_a_files)"

  - id: desc_a_list
    type: string[]
    label: "descriptions A"
    doc: "One descriptionA per scatter job (empty string uses basename of data_a)"

  - id: desc_b_list
    type: string[]
    label: "descriptions B"
    doc: "One descriptionB per scatter job (empty string uses basename of data_b)"

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
  - id: diff_job
    run: chip_atlas_diff_job.cwl
    scatter:
      - data_a
      - data_b
      - antigen_class
      - title
      - result_basename
      - desc_a
      - desc_b
    scatterMethod: dotproduct
    in:
      data_a: data_a_files
      data_b: data_b_files
      antigen_class: antigen_classes
      title: job_titles
      result_basename: result_basenames
      desc_a: desc_a_list
      desc_b: desc_b_list
      genome: genome
      sbatch_options: sbatch_options
      skip_preflight: skip_preflight
      url_input: url_input
      poll_interval: poll_interval
      out_dir: out_dir
    out:
      - request_id
      - submit_response
      - submit_log
      - status_log
      - result_bed
      - result_igv_bed
      - result_xml
      - result_log
      - readme

outputs:
  - id: request_ids
    type: string[]
    label: "request IDs"
    outputSource: diff_job/request_id

  - id: submit_responses
    type: File[]
    label: "submit responses"
    outputSource: diff_job/submit_response

  - id: submit_logs
    type: File[]
    label: "submit logs"
    outputSource: diff_job/submit_log

  - id: status_logs
    type: File[]
    label: "status logs"
    outputSource: diff_job/status_log

  - id: result_beds
    type: File[]
    label: "result BED files"
    outputSource: diff_job/result_bed

  - id: result_igv_beds
    type: File[]
    label: "result IGV BED files"
    outputSource: diff_job/result_igv_bed

  - id: result_xmls
    type: File[]
    label: "result XML files"
    outputSource: diff_job/result_xml

  - id: result_logs
    type: File[]
    label: "analysis logs"
    outputSource: diff_job/result_log

  - id: readmes
    type: File[]
    label: "README files"
    outputSource: diff_job/readme

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
