#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "ChIP-Atlas enrichment submit"
doc: |
  Submit a ChIP-Atlas Enrichment Analysis job (typeA=bed, typeB=bed)
  via scripts/chip_atlas_enrichment_analysis.sh.
  Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Enrichment-Analysis-programmatically

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}
  NetworkAccess:
    networkAccess: true

stdout: $(inputs.result_basename)_submit_response.txt
stderr: $(inputs.result_basename)_submit_log.txt

baseCommand: bash

arguments:
  - valueFrom: $(inputs.submit_script.path)
  - prefix: -S
    valueFrom: $(inputs.sbatch_options)
    shellQuote: true
  - prefix: -c
    valueFrom: $(inputs.cell_class)
  - prefix: -t
    valueFrom: $(inputs.threshold)
  - prefix: -g
    valueFrom: $(inputs.genome)
  - prefix: -a
    valueFrom: $(inputs.desc_a)
  - prefix: -b
    valueFrom: $(inputs.desc_b)
  - valueFrom: $(inputs.bed_a.path)
  - valueFrom: $(inputs.bed_b.path)
  - valueFrom: $(inputs.antigen_class)
  - valueFrom: $(inputs.title)

inputs:
  - id: submit_script
    type: File
    label: "submit script"
    doc: "chip_atlas_enrichment_analysis.sh"
    default:
      class: File
      location: ../../scripts/chip_atlas_enrichment_analysis.sh

  - id: bed_a
    type: File
    label: "Dataset A BED file"
    doc: "User query regions BED file (Dataset A)"

  - id: bed_b
    type: File
    label: "Dataset B BED file"
    doc: "Compiled peaks BED file (Dataset B)"

  - id: antigen_class
    type:
      type: enum
      symbols:
        - Histone
        - "TFs and others"
        - "RNA polymerase"
        - ATAC-Seq
        - DNase-seq
        - Bisulfite-Seq
        - "Input control"
    label: "antigen class"
    doc: "ChIP-Atlas antigenClass parameter"

  - id: title
    type: string
    label: "job title"
    doc: "Job title passed to ChIP-Atlas wabi API"

  - id: result_basename
    type: string
    label: "result file basename"
    doc: "Prefix for submit_log / submit_response output files"

  - id: cell_class
    type: string
    label: "cell type class"
    doc: "ChIP-Atlas cellClass parameter"
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
    doc: "MACS2 q-value threshold (auto-overridden to 999 for Bisulfite-Seq by the shell script)"
    default: "100"

  - id: genome
    type: string
    label: "genome assembly"
    doc: "Genome assembly (e.g. hg38, hg19, mm10)"
    default: hg38

  - id: desc_a
    type: string
    label: "description A"
    doc: "Dataset A description (descriptionA)"

  - id: desc_b
    type: string
    label: "description B"
    doc: "Dataset B description (descriptionB)"

  - id: sbatch_options
    type: string
    label: "SLURM sbatch options"
    doc: "SLURM sbatch options passed as sbatchOptions (required for job dispatch)"
    default: "-p epyc -t 180"

outputs:
  - id: submit_log
    type: File
    label: "submit log"
    doc: "Resolved submit parameters and diagnostics written by the shell script to stderr"
    outputBinding:
      glob: $(inputs.result_basename)_submit_log.txt

  - id: submit_response
    type: File
    label: "submit response"
    doc: "Raw wabi API response body from job submission"
    outputBinding:
      glob: $(inputs.result_basename)_submit_response.txt

  - id: request_id
    type: string
    label: "request ID"
    doc: "Parsed wabi requestId from the submit response"
    outputBinding:
      glob: $(inputs.result_basename)_submit_response.txt
      loadContents: true
      outputEval: |
        ${ var m = self[0].contents.match(/requestId:\s*(\S+)/);
          if (!m) throw "requestId not found in submit response";
          return m[1]; }

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
