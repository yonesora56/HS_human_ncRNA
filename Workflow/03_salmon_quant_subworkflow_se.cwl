#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "step5: Salmon quantification for multiple single-end RNA-seq samples"
doc: |
  Performs Salmon quantification for multiple single-end RNA-seq samples.
  Each sample is processed by the '05_salmon_quant_se.cwl' tool using the scatter feature.
  The Salmon index and other parameters like library type, threads, and number of bootstraps
  are applied commonly to all scattered jobs.

requirements:
  ScatterFeatureRequirement: {}
  InlineJavascriptRequirement: {} # Needed if the tool or this workflow uses JS expressions for path manipulation etc.

inputs:
  - id: single_end_trimmed_reads
    type: File[]
    format: edam:format_1930
    label: "Array of single-end trimmed FASTQ files"
    doc: "An array of single-end trimmed FASTQ files, one for each sample to be quantified."

  - id: salmon_index_wf
    type: Directory
    label: "Salmon index directory (Workflow input)"
    doc: "Path to the Salmon index directory. This will be passed to each Salmon job. (e.g. ../index_fantomcat_stringent_lv4_full_decoy)"
    # Optionally, provide a default if it's often the same
    default:
      class: Directory
      location: ../index_fantomcat_stringent_lv4_full_decoy

  - id: library_type_wf
    type: string
    label: "Library type (Workflow input)"
    doc: "Library type (e.g., A, U, SF, SR). Passed to each Salmon job."
    default: "A"

  - id: threads_wf
    type: int
    label: "Threads per Salmon job (Workflow input)"
    doc: "Number of threads to use for each individual Salmon quantification job."
    default: 16 # Consider if a smaller default per job is better if many jobs run in parallel

  - id: num_bootstraps_wf
    type: int
    label: "Number of bootstraps per Salmon job (Workflow input)"
    doc: "Number of bootstraps for each Salmon quantification job."
    default: 0

steps:
  - id: salmon_quant_scatter_step
    run: ../Tools/05_salmon_quant_se.cwl
    scatter: [single_end_trimmed_read] # The input field in the tool to scatter over
    in:
      # Mapping workflow inputs to the tool's inputs
      single_end_trimmed_read: single_end_trimmed_reads # Scatter this array
      salmon_index: salmon_index_wf # Use the common index for all jobs
      library_type: library_type_wf # Use the common library type
      threads: threads_wf # Use the common thread count
      num_bootstraps: num_bootstraps_wf # Use the common bootstrap count
    out: [salmon_quant_output] # The output ID from the tool

outputs:
  - id: salmon_quant_output_array
    type: Directory[] # This will be an array of directories
    label: "Array of Salmon quantification output directories"
    doc: "An array of directories, where each directory contains the Salmon quantification results for one input sample."
    outputSource: salmon_quant_scatter_step/salmon_quant_output

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/