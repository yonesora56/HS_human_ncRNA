#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "dump one Hi-C chromosome matrix with HiC1Dmetrics"
doc: |
  Dump one intra-chromosomal dense matrix from a Juicer .hic file by calling
  scripts/hic1dmetrics_dump.py (h1d makeMatrixIntra.sh / juicer_tools dump).
  One job handles one sample and one chromosome so a workflow can scatter later.

  The output file name is composed from parameter references only
  (no InlineJavascriptRequirement):
    $(hic_file.nameroot).$(normalize).$(chromosome).$(resolution).matrix.gz

  help:
    python3 scripts/hic1dmetrics_dump.py --help
  documentation:
    https://h1d.readthedocs.io/en/latest/basic.html#make-contact-matrix

baseCommand: [python3]

arguments:
  - $(inputs.dump_script)
  - --hic-file
  - $(inputs.hic_file)
  - --genome-table
  - $(inputs.genome_table)
  - --juicer-tools
  - $(inputs.juicer_tools)
  - --chromosome
  - $(inputs.chromosome)
  - --resolution
  - $(inputs.resolution)
  - --normalize
  - $(inputs.normalize)
  - --output-matrix-file
  - $(inputs.hic_file.nameroot).$(inputs.normalize).$(inputs.chromosome).$(inputs.resolution).matrix.gz

inputs:
  - id: dump_script
    type: File
    label: "hic1dmetrics dump script"
    doc: "Python wrapper around h1d makeMatrixIntra.sh"
    default:
      class: File
      location: ../../scripts/hic1dmetrics_dump.py

  - id: hic_file
    type: File
    label: "Juicer hic file"
    doc: "Input .hic file for one sample"
    default:
      class: File
      location: ../../out/hic/GSE105028_hic_convert_hic/HiC_Ctrl_merged_juicer_pre_output/HiC_Ctrl_merged.hic

  - id: genome_table
    type: File
    label: "HiC1Dmetrics genome table"
    doc: "Tab-separated chromosome lengths for h1d --gt"
    format: iana:text/tab-separated-values
    default:
      class: File
      format: iana:text/tab-separated-values
      location: ../../out/h1d/hg38_genome_table.txt

  - id: juicer_tools
    type: File
    label: "juicer_tools jar"
    doc: "juicer_tools jar used by dump (2.20.00 for HIC v9)"
    default:
      class: File
      location: ../../out/h1d/juicer_tools.2.20.00.jar

  - id: chromosome
    type: string
    label: "chromosome"
    doc: "Chromosome name matching the genome table, e.g. chr21"
    default: "chr21"

  - id: resolution
    type: int
    label: "resolution (bp)"
    doc: "Bin size in bp"
    default: 5000

  - id: normalize
    type:
      type: enum
      symbols: [NONE, VC, VC_SQRT, KR]
    label: "Juicer normalization"
    doc: "Normalization method passed to juicer_tools dump"
    default: KR

outputs:
  - id: contact_matrix_file
    type: File
    label: "dense contact matrix"
    doc: "Gzipped intra-chromosomal dense matrix from h1d dump"
    streamable: true
    outputBinding:
      glob: $(inputs.hic_file.nameroot).$(inputs.normalize).$(inputs.chromosome).$(inputs.resolution).matrix.gz

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
  iana: https://www.iana.org/assignments/media-types/
