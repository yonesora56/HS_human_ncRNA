#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "bedtools intersect on the opposite strand (-S -wo)"
doc: |
  Find overlaps between two BED files on the opposite strand.

  bedtools intersect -S keeps a B interval only when it overlaps A on the
  other strand. Strand is column 6. Same-strand overlaps are dropped.
  -wo writes every column of A, every column of B, and the overlap width
  in bp as the last column. bedtools does not allow -wa/-wb together with -wo.

  For GENCODE antisense pairs, pass transcript-feature rows (column 8 is
  "transcript") as both -a and -b. Each row is one transcript span, and
  column 4 is the transcript id. Gene rows have "." in column 4. Exon rows
  split one transcript into many intervals.

  This tool does not pass -sorted. bedtools intersect still runs when the
  inputs are unsorted. For the full GENCODE transcript BED, pre-sort both
  files (sort -k1,1 -k2,2n) before a later -sorted tool if memory is tight.

  Output columns:
    [all columns from query BED (-a)]
    [all columns from database BED (-b)]
    [overlap_bp]

  bedtools writes the intersect table to stdout, so that stream is the BED
  file. Warnings, including the Docker platform message, go to stderr and
  are captured as a log.

  help:
    docker run --rm quay.io/biocontainers/bedtools:2.31.1--h13024bc_3 bedtools intersect --help
  documentation:
    https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html

baseCommand: [bedtools, intersect]

arguments:
  - -a
  - $(inputs.query_bed_file)
  - -b
  - $(inputs.query_bed_file)
  - -S
  - -wo

stdout: $(inputs.query_bed_file.nameroot)_opposite_strand_intersecting_$(inputs.query_bed_file.nameroot).bed
stderr: $(inputs.query_bed_file.nameroot)_stderr.log

inputs:
  - id: query_bed_file
    type: File
    label: "query BED file (A)"
    doc: |
      Query BED (-a). Strand must be in column 6.
      For a GENCODE antisense survey, use transcript-feature rows.
    format: edam:format_3003
    default:
      class: File
      format: edam:format_3003
      location: ../Data/Database/GENCODE_v49/gencode.v49.annotation_transcript_id_only.bed

outputs:
  - id: intersect_output_file
    type: File
    label: "opposite-strand intersect BED"
    doc: |
      A and B entries that overlap on opposite strands.
      The last column is overlap width in bp (-wo).
      Each pair is written twice, once in each direction.
    format: edam:format_3003
    streamable: true
    outputBinding:
      glob: $(inputs.query_bed_file.nameroot)_opposite_strand_intersecting_$(inputs.query_bed_file.nameroot).bed

  - id: stderr_log
    type: File
    label: "stderr log"
    doc: "stderr captured by cwltool, including bedtools warnings and the Docker platform warning."
    outputBinding:
      glob: $(inputs.query_bed_file.nameroot)_stderr.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/bedtools:2.31.1--h13024bc_3

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/
