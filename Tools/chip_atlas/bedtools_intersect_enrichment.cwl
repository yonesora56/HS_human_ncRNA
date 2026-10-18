#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "bedtools intersect"
doc: |
  "Find overlaps between two BED files using bedtools intersect.
  Options match ChIP-Atlas enrichment-analysis.py (-a, -b, -wa, -wb).
  help: docker run --rm quay.io/biocontainers/bedtools:2.31.1--h13024bc_3 bedtools intersect --help
  base script: https://github.com/inutano/chip-atlas-pipeline-v2/blob/master/scripts/secondary-analysis/enrichment-analysis.py
  documentation: https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html?highlight=intersect
  "

baseCommand: [bedtools, intersect]

arguments:
  - -a
  - $(inputs.query_bed_file)
  - -b
  - $(inputs.peaks_bed_file)
  - -wa
  - -wb

stdout: $(inputs.query_bed_file.nameroot)_intersecting_$(inputs.peaks_bed_file.nameroot).bed

inputs:
  - id: query_bed_file
    type: File
    label: "query BED file (A)"
    doc: "User query regions BED file (-a), as in enrichment-analysis.py"
    default:
      class: File
      location: ../../Data/Database/fanta_bio/human-CREv1.2.1.hg38.cre-peaks.bed

  - id: peaks_bed_file
    type: File
    label: "compiled peaks BED file (B)"
    doc: "Compiled peaks BED file (-b), as in enrichment-analysis.py"
    default:
      class: File
      location: ../../out/ChIP-Atlas_diff/ATACseq/bed_diff/GSE101731_ata_1hHS.bed

outputs:
  - id: intersect_output_file
    type: File
    label: "intersect output BED file"
    doc: "BED file with overlapping A and B entries (-wa -wb)"
    outputBinding:
      glob: $(inputs.query_bed_file.nameroot)_intersecting_$(inputs.peaks_bed_file.nameroot).bed

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bedtools:2.31.1--h13024bc_3

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
