#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "bedtools intersect scatter"
doc: |
  "Run bedtools intersect for one query BED against multiple peaks BED files.
  Uses scatter to execute Tools/chip_atlas/bedtools_intersect.cwl in parallel.
  "

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: query_bed_file
    type: File
    label: "query BED file (A)"
    doc: "User query regions BED file shared across all intersect jobs"
    default:
      class: File
      location: ../Data/Database/fanta_bio/human-CREv1.2.1.hg38.cre-peaks.bed

  - id: peaks_bed_files
    type: File[]
    label: "peaks BED files (B)"
    doc: "Peaks BED files to intersect with the query BED"

steps:
  - id: bedtools_intersect
    run: ../Tools/chip_atlas/bedtools_intersect_diff.cwl
    scatter: [peaks_bed_file]
    scatterMethod: dotproduct
    in:
      query_bed_file: query_bed_file
      peaks_bed_file: peaks_bed_files
    out: [intersect_output_file]

outputs:
  - id: intersect_output_files
    type: File[]
    label: "intersect output BED files"
    doc: "BED files with overlapping A and B entries (-wa -wb) for each peaks BED"
    outputSource: bedtools_intersect/intersect_output_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
