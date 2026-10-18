#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "prepare FANTOM-CAT BED12 formatted for bed2gtf"
doc: |
  Rewrite CrossMap BED12 so bed2gtf 2.0.0 can parse it:
    - column 4: keep transcript_id after "|"
    - column 5: set score to 0 (TIEScore floats are rejected)
    - column 9: set itemRgb to 0,0,0 ("." is rejected)

  help:
    docker run --rm quay.io/biocontainers/gawk:5.1.0--2 gawk --help

requirements:
  - class: ShellCommandRequirement

arguments:
  - shellQuote: false
    valueFrom: |
      gawk 'BEGIN{FS=OFS="\t"} { n=split($4,a,"|"); $4=(n>=2?a[2]:$4); $5=0; $9="0,0,0"; print }' "$(inputs.input_bed_file.path)"

stdout: $(inputs.output_bed_file_name)

inputs:
  - id: input_bed_file
    type: File
    label: "Input BED12 file (hg38)"
    doc: "CrossMap output BED12 (e.g. FANTOM_CAT.lv4_stringent.hg38.bed)"
    format: edam:format_3003
    default:
      class: File
      format: edam:format_3003
      location: ../../Data/Database/FANTOM/FANTOM-CAT/FANTOM_CAT.lv4_stringent.hg38.bed


  - id: output_bed_file_name
    type: string
    label: "Output BED file name"
    doc: "BED12 file name for bed2gtf --input"
    default: "FANTOM_CAT.lv4_stringent.hg38.txid.bed"

outputs:
  - id: output_bed_file
    type: File
    label: "Prepared BED12 file"
    doc: "BED12 with transcript_id name, integer score, and RGB itemRgb"
    format: edam:format_3003
    streamable: true
    outputBinding:
      glob: $(inputs.output_bed_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/gawk:5.1.0--2

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
