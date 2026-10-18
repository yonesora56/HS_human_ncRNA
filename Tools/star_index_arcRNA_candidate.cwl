#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "make star index"
doc: |
  "create star index for reference genome (STAR version 2.7.11b)
  help: docker run --rm quay.io/biocontainers/star:2.7.11b--h5ca1c30_8 STAR --help
  base file: https://github.com/RyoNozu/CWL4IncorporateTSSintoGXF/blob/main/Tools/04_make_star_index.cwl
  --sjdbOverhang is 49, not STAR's default of 100 (meant for ~101 bp reads).
  The FASTQs mapped with this index are trimmed single-end reads:
  PRJDB9451 is 50 bp (fastp max 50 cycles) and PRJDB12380 is 36 bp (fastp max 36 cycles).
  STAR's ideal value is max(ReadLength)-1, so the shared index uses 50-1=49.
  --limitGenomeGenerateRAM is raised above STAR's 31000000000 byte default
  so genomeGenerate can hold the full GENCODE v49 GTF on a 128 GB machine.
  "
requirements:
  ShellCommandRequirement: {}

inputs:
  - id: output_dir_name
    type: string
    label: "output directory name"
    doc: "output directory name"
    default: "grch38_genome_idx"

  - id: reference_genome
    type: File
    label: "reference genome fasta file"
    doc: "reference genome fasta file"
    format: edam:format_1929
    default:
      class: File
      format: edam:format_1929
      location: ../Data/GENCODE_v49/GRCh38.primary_assembly.genome.fa

  - id: reference_genome_annotation
    type: File
    label: "GFF format reference genome annotation file"
    doc: "GFF format reference genome annotation file"
    format: edam:format_2305 # GFF format (including GTF, GFF3)
    default:
      class: File
      format: edam:format_2305 # GFF format (including GTF, GFF3)
      location: ../Data/GENCODE_v49/gencode.v49.annotation.gtf

  - id: sjdb_overhang
    type: int
    label: "sjdbOverhang"
    doc: |
      Donor/acceptor sequence length on each side of annotated junctions.
      Ideal value is max(ReadLength)-1. Default 49 matches the longer
      library here (PRJDB9451, 50 bp); PRJDB12380 is 36 bp and shares this index.
    default: 49

  - id: limit_genome_generate_ram
    type: long
    label: "limitGenomeGenerateRAM"
    doc: |
      Maximum RAM in bytes for genomeGenerate.
      STAR default is 31000000000. Raised so the full GENCODE v49 GTF fits.
    default: 100000000000

  - id: star_threads
    type: int
    label: "threads for star"
    doc: "threads for star"
    default: 18

stdout: prepare_star-index.log
stderr: prepare_star-index.log


arguments:
  - shellQuote: false
    valueFrom: |
      echo "Start to make STAR index for reference genome gtf file" "`date '+%Y/%m/%d %H:%M:%S'`"
      STAR --version
      mkdir --verbose --parents $(inputs.output_dir_name)
      STAR --runMode genomeGenerate \
      --genomeDir $(inputs.output_dir_name) \
      --genomeFastaFiles $(inputs.reference_genome.path) \
      --sjdbGTFfile $(inputs.reference_genome_annotation.path) \
      --sjdbOverhang $(inputs.sjdb_overhang) \
      --limitGenomeGenerateRAM $(inputs.limit_genome_generate_ram) \
      --runThreadN $(inputs.star_threads)

outputs:
  - id: index_output_dir
    type: Directory
    label: "STAR index output directory"
    doc: "STAR index output directory (including text files, log files, etc.)"
    outputBinding:
      glob: $(inputs.output_dir_name)

  - id: stdout_log
    type: File
    label: "stdout log"
    doc: "stdout log"
    outputBinding:
      glob: prepare_star-index.log

  - id: stderr_log
    type: File
    label: "stderr log"
    doc: "stderr log"
    outputBinding:
      glob: prepare_star-index.log   

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/star:2.7.11b--h5ca1c30_8

$namespaces:
  s: https://schema.org/
  edam: https://edamontology.org/