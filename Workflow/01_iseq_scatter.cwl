#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "iseq_scatter"
doc: "iseq_scatter"

requirements:
  ScatterFeatureRequirement: {}
  NetworkAccess:
    networkAccess: true

inputs:
  - id: accession_numbers
    type: string[]
    label: "accession_numbers"
    doc: "accession_numbers"

  - id: threads
    type: int
    label: "threads"
    doc: "threads"
    default: 16

  - id: parallel_number
    type: int
    label: "parallel_number"
    doc: "parallel_number"
    default: 8

steps:
  - id: retrieve_fastq_file
    run: ../Tools/01_iseq_zatsu.cwl
    scatter: [accession]
    scatterMethod: dotproduct
    in:
      accession: accession_numbers
      threads: threads
      parallel_number: parallel_number
    out: [fastq_gz_file, success_log, fail_log]


outputs:
  - id: fastq_gz_files
    type: File[]
    label: "fastq_gz_files"
    doc: "fastq_gz_files"
    outputSource: retrieve_fastq_file/fastq_gz_file


$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/