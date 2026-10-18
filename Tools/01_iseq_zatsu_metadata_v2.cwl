#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "iseq"
doc: "iseq"

requirements:
  ShellCommandRequirement: {}
  NetworkAccess:
    networkAccess: true

arguments:
  - shellQuote: false
    valueFrom: |
      iseq --input $(inputs.accession) --metadata

inputs:
  - id: accession
    type: string
    label: "accession"
    doc: "accession"
    default: "GSE253874"

  - id: threads
    type: int
    label: "threads"
    doc: "threads"
    default: 16

  - id: parallel_number
    type: int
    label: "parallel_number"
    doc: "parallel_number"
    default: 1


outputs:
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/iseq:1.9.8--hdfd78af_0

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/