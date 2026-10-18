#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "Extract BED regions as FASTA with bed2fasta"
doc: |
  Extract genomic sequence for each BED interval with MEME Suite bed2fasta.

  Intended inputs:
    BED:    Data/Database/fantabio/human-CREv1.2.1.hg38.cre-peaks.bed
    genome: Data/Database/GENCODE_v49/genome/GRCh38.p14.genome.fa

  Chromosome names must match. Both of those files use UCSC-style names (chr1).
  GENCODE sequence headers may carry a second token (">chr1 1"); bed2fasta
  uses the first token as the sequence name.

  NOTE: The genome FASTA must have a sibling index named "<genome>.fai", declared
  here as secondaryFiles. Create it with the same image before running:

    docker run --rm -v "$PWD":/work -w /work \
      quay.io/biocontainers/meme:5.5.9--pl5321he99cc7f_1 \
      fasta-file-indexer Data/Database/GENCODE_v49/genome/GRCh38.p14.genome.fa

  Fixed flags (no runtime branching):
    -name  FASTA identifier is BED column 4 (FCHS_* on the CRE peaks BED).
           Coordinate-only headers, or -both, belong in a separate tool.
    -s is not set. The CRE peaks BED stores "." in the strand column, so
           sequences are the forward genomic strand. A stranded BED needs
           a separate tool that passes -s.

  help:
    docker run --rm quay.io/biocontainers/meme:5.5.9--pl5321he99cc7f_1 bed2fasta
  documentation:
    https://meme-suite.org/meme/doc/bed2fasta.html

baseCommand: [bed2fasta]

arguments:
  - -name
  - $(inputs.regions_bed)
  - $(inputs.genome_fasta)

stdout: $(inputs.regions_bed.nameroot).fa

inputs:
  - id: regions_bed
    type: File
    label: "regions BED file"
    doc: |
      Genomic intervals in BED format. Column 4 is written as the FASTA
      identifier because -name is fixed. At least three columns are required;
      column 4 must be present for -name.
    format: edam:format_3003
    default:
      class: File
      format: edam:format_3003
      location: ../Data/Database/fantabio/human-CREv1.2.1.hg38.cre-peaks.bed


  - id: genome_fasta
    type: File
    label: "genome FASTA"
    doc: |
      Reference genome FASTA whose sequence names match the BED chromosomes.
      Requires a secondary index at <genome fasta>.fai from fasta-file-indexer.
    format: edam:format_1929
    default:
      class: File
      format: edam:format_1929
      location: ../Data/Database/GENCODE_v49/genome/GRCh38.p14.genome.fa
    secondaryFiles:
      - .fai

outputs:
  - id: region_sequences
    type: File
    label: "region sequences FASTA"
    doc: |
      One FASTA record per legal BED interval. The identifier is BED column 4.
    format: edam:format_1929
    streamable: true
    outputBinding:
      glob: $(inputs.regions_bed.nameroot).fa

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/meme:5.5.9--pl5321he99cc7f_1

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
