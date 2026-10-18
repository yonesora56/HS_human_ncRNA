#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "make HiC1Dmetrics genome table"
doc: |
  Extract canonical chromosome sizes (chr1-22, chrX, chrY) from a
  samtools-style genome file and write a two-column tab-separated
  genome table for HiC1Dmetrics (--gt).

  Example command:
    gawk 'BEGIN{FS=OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2]|X|Y)$/ {print $1,$2}' \
      GRCh38_p14_genome.genome > hg38_genome_table.txt

  help:
    docker run --rm quay.io/biocontainers/gawk:5.1.0--2 gawk --help
  documentation:
    https://h1d.readthedocs.io/en/latest/overview.html#input-format

baseCommand: [gawk, 'BEGIN{FS=OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2]|X|Y)$/ {print $1,$2}']

arguments:
  - $(inputs.genome_file)

stdout: $(inputs.output_genome_table_file_name)

inputs:
  - id: genome_file
    type: File
    label: "samtools-style genome file"
    doc: "Chromosome sizes file with at least two columns (chromosome, length), e.g. samtools faidx --output"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../../Data/Database/GENCODE_v49/genome/GRCh38_p14_genome.genome

  - id: output_genome_table_file_name
    type: string
    label: "Output genome table file name"
    doc: "Two-column tab-separated genome table for HiC1Dmetrics --gt"
    default: "hg38_genome_table.txt"

outputs:
  - id: genome_table_file
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths (chr1-22, chrX, chrY) for HiC1Dmetrics --gt"
    format: iana:text/tab-separated-values
    streamable: true
    outputBinding:
      glob: $(inputs.output_genome_table_file_name)

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/gawk:5.1.0--2

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
