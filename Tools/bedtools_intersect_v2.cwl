#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "bedtools intersect (v2: -wo, optional overlap filters)"
doc: |
  Find overlaps between two BED files using bedtools intersect.

  Default behavior matches the ENCODE-rE2G / fanta.bio intersect use case:
  - write original A and B entries plus overlap bp (-wo)

  Note: bedtools does not allow -wa/-wb together with -wo. The -wo flag already
  writes both A and B entries and appends overlap width as the last column.

  For -wa/-wb output without overlap bp, use Tools/bedtools_intersect.cwl instead.

  Sorting: this tool does NOT pass -sorted. Query BEDs from upstream references
  (e.g. ENCODE-rE2G RefSeq TSS500bp) may be unsorted. bedtools intersect still
  works without -sorted; for very large database BEDs, pre-sort both inputs
  (sort -k1,1 -k2,2n) and use a -sorted variant if memory becomes an issue.

  Output format (with -wo):
    [all columns from query BED (-a)]
    [all columns from database BED (-b)]
    [overlap_bp]

  Polars can read the last column as overlap_bp and only compute query-side
  fraction, e.g. overlap_frac_of_query = overlap_bp / (query_end - query_start).

  help:
    docker run --rm quay.io/biocontainers/bedtools:2.31.1--h13024bc_3 bedtools intersect --help
  documentation:
    https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html

baseCommand: [bedtools, intersect]

arguments:
  - -a
  - $(inputs.query_bed_file)
  - -b
  - $(inputs.peaks_bed_file)
  - -wo

stdout: $(inputs.query_bed_file.nameroot)_intersecting_$(inputs.peaks_bed_file.nameroot).bed

inputs:
  - id: query_bed_file
    type: File
    label: "query BED file (A)"
    doc: |
      Query regions BED file (-a). Sorting not required for this tool.
    format: edam:format_3003

  - id: peaks_bed_file
    type: File
    label: "database BED file (B)"
    doc: |
      Database regions BED file (-b). Sorting not required for this tool.
    format: edam:format_3003

outputs:
  - id: intersect_output_file
    type: File
    label: "intersect output BED file"
    doc: |
      BED-like file with overlapping A and B entries.
      The last column is overlap width in bp (-wo).
    format: edam:format_3003
    streamable: true
    outputBinding:
      glob: $(inputs.query_bed_file.nameroot)_intersecting_$(inputs.peaks_bed_file.nameroot).bed

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bedtools:2.31.1--h13024bc_3

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
