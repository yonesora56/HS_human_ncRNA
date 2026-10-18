#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "iseq_zatsu_scatter"
doc: "Scatter iseq downloads across multiple accessions in parallel"

requirements:
  ScatterFeatureRequirement: {}
  NetworkAccess:
    networkAccess: true

inputs:
  - id: accession_numbers
    type: string[]
    label: "accession_numbers"
    doc: "List of accession numbers to download in parallel"

  - id: threads
    type: int
    label: "threads"
    doc: "threads"
    default: 16

  - id: parallel_number
    type: int
    label: "parallel_number"
    doc: "parallel_number"
    default: 2

steps:
  - id: retrieve_fastq_file
    run: ../Tools/01_iseq_zatsu.cwl
    # Scatter over the accession input so each accession is downloaded independently
    scatter: [accession]
    scatterMethod: dotproduct
    in:
      accession: accession_numbers
      threads: threads
      parallel_number: parallel_number
    out: [all-for-debugging]


outputs:
  - id: all-for-debugging
    # Nested array: one inner array of File/Directory per scattered accession
    type:
      type: array
      items:
        type: array
        items: [File, Directory]
    label: "all-for-debugging"
    doc: "Per-accession outputs collected from each scattered iseq run"
    outputSource: retrieve_fastq_file/all-for-debugging


$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/
