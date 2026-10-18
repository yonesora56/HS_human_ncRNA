#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "ChIP-Atlas diff analysis submit"
doc: |
  Submit a ChIP-Atlas Diff Analysis job via scripts/chip_atlas_diff_analysis.sh.
  Wiki: https://github.com/inutano/chip-atlas/wiki/Perform-Diff-Analysis-Programmatically

  Fixed wabi POST parameters (not exposed as CWL inputs; set inside submit_script):
    format=text, result=www, cellClass=empty, typeA=srx, typeB=srx, permTime=1

  Variable wabi POST parameters (mapped to CWL inputs below):
    genome, antigenClass, bedAFile, bedBFile, title, descriptionA, descriptionB, sbatchOptions

  help:
    bash scripts/chip_atlas_diff_analysis.sh -h

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}
  NetworkAccess:
    networkAccess: true

stdout: $(inputs.result_basename)_submit_response.txt
stderr: $(inputs.result_basename)_submit_log.txt

baseCommand: [bash]

arguments:
  - valueFrom: $(inputs.submit_script.path)
  - valueFrom: |
      ${ if (inputs.url_input) return "-u"; return null; }
  - valueFrom: |
      ${ if (inputs.skip_preflight) return "-x"; return null; }
  - prefix: -t
    valueFrom: "50"
  - prefix: -g
    valueFrom: $(inputs.genome)
  - prefix: -a
    valueFrom: $(inputs.desc_a)
  - prefix: -b
    valueFrom: $(inputs.desc_b)
  - prefix: -S
    valueFrom: $(inputs.sbatch_options)
    shellQuote: true
  - valueFrom: $(inputs.data_a.path)
  - valueFrom: $(inputs.data_b.path)
  - valueFrom: $(inputs.antigen_class)
  - valueFrom: $(inputs.title)

inputs:
  - id: submit_script
    type: File
    label: "submit script"
    doc: "chip_atlas_diff_analysis.sh (chip_atlas_diff_common.sh staged via secondaryFiles)"
    default:
      class: File
      location: ../../scripts/chip_atlas_diff_analysis.sh
      secondaryFiles:
        - class: File
          location: ../../scripts/chip_atlas_diff_common.sh

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
    doc: "diffbind (DPR) or dmr (DMR). dmr auto-overrides threshold to 999 inside submit_script."

  - id: title
    type: string
    label: "job title"
    doc: "Job title passed to ChIP-Atlas wabi API"

  - id: result_basename
    type: string
    label: "result file basename"
    doc: "Prefix for submit_log / submit_response output files"

  - id: genome
    type: string
    label: "genome assembly"
    doc: "Genome assembly (e.g. hg38, hg19, mm10)"
    default: hg38

  - id: desc_a
    type: string
    label: "description A"
    doc: "Dataset A description (descriptionA). Empty string uses basename of data_a."

  - id: desc_b
    type: string
    label: "description B"
    doc: "Dataset B description (descriptionB). Empty string uses basename of data_b."

  - id: sbatch_options
    type: string
    label: "SLURM sbatch options"
    doc: "SLURM sbatch options passed as sbatchOptions (required for job dispatch)"
    default: "-p epyc -t 180"

  - id: skip_preflight
    type: boolean
    label: "skip preflight checks"
    doc: "When true, pass -x to skip ChIP-Atlas asset preflight checks"
    default: false

  - id: url_input
    type: boolean
    label: "URL input mode"
    doc: "When true, pass -u to convert accession ID lists to ChIP-Atlas URL rows"
    default: false

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
