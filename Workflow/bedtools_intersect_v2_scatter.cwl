#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "bedtools intersect v2 scatter (-wo)"
doc: |
  Run Tools/bedtools_intersect_v2.cwl for multiple query BED files against one
  database BED (e.g. ENCODE-rE2G enhancer BEDs vs. fanta.bio CRE peaks).

  Each job uses -wo (overlap width in the last column). Scatter runs over
  query_bed_files; peaks_bed_file is shared.

  Output basename (from the tool):
    {query.nameroot}_intersecting_{peaks.nameroot}.bed

  If several query files share the same basename, set a unique File.basename
  in the inputs YAML so --outdir writes do not collide.

  Example:
    cwltool --outdir ./out/ENCODE_rE2G/bedtools_intersect/ \
      ./Workflow/bedtools_intersect_v2_scatter.cwl \
      ./config/ENCODE_rE2G/hs_atacseq_hic_list_re2g_enhancer_intersect_fantabio_cre.yml

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: query_bed_files
    type: File[]
    label: "query BED files (A)"
    doc: |
      Query region BED files (-a), one job per file.
      Use File.basename when input basenames are not unique.
    format: edam:format_3003

  - id: peaks_bed_file
    type: File
    label: "database BED file (B)"
    doc: "Database regions BED file (-b) shared across all intersect jobs"
    format: edam:format_3003
    default:
      class: File
      location: ../Data/Database/fanta_bio/human-CREv1.2.1.hg38.cre-peaks.bed

steps:
  - id: bedtools_intersect
    run: ../Tools/bedtools_intersect_v2.cwl
    scatter: [query_bed_file]
    scatterMethod: dotproduct
    in:
      query_bed_file: query_bed_files
      peaks_bed_file: peaks_bed_file
    out: [intersect_output_file]

outputs:
  - id: intersect_output_files
    type: File[]
    label: "intersect output BED files"
    doc: |
      BED-like files with overlapping A and B entries.
      The last column is overlap width in bp (-wo).
    format: edam:format_3003
    outputSource: bedtools_intersect/intersect_output_file

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
