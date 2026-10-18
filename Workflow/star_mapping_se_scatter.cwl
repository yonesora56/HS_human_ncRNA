#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
label: "scatter single-end RNA-seq STAR mapping"
doc: |
  Map each trimmed single-end RNA-seq FASTQ with Tools/star_mapping_se.cwl.
  Scatter follows https://www.commonwl.org/user_guide/topics/scattering-workflows.html
  Only rnaseq_read is scattered. The STAR index, thread count, and
  --outFilterMultimapNmax are shared by every sample.

  Intended reads: PRJDB9451 (50 bp) and PRJDB12380 (36 bp), TruSeq Stranded single-end.
  Gene counts are not produced here; featureCounts (-s 2) is a later step.

requirements:
  ScatterFeatureRequirement: {}

inputs:
  - id: rnaseq_reads
    type: File[]
    label: "trimmed single-end RNA-seq FASTQs"
    doc: "One gzip-compressed FASTQ per sample. Each file is one scatter job."

  - id: star_index_dir
    type: Directory
    label: "STAR index directory"
    doc: "Genome index from Tools/star_index.cwl (sjdbOverhang 49). Shared across samples."

  - id: out_filter_multimap_nmax
    type: int
    label: "outFilterMultimapNmax"
    doc: |
      Maximum number of loci reported for one read.
      Default 1 follows Iwakiri et al.: only uniquely mapped reads are written.
    default: 1

  - id: star_threads
    type: int
    label: "threads for STAR"
    doc: "CPU threads passed to each scatter job (--runThreadN)."
    default: 18

steps:
  - id: map_rnaseq
    label: "STAR map one FASTQ"
    doc: "One Tools/star_mapping_se.cwl run per FASTQ."
    run: ../Tools/star_mapping_se.cwl
    scatter: rnaseq_read
    in:
      rnaseq_read: rnaseq_reads
      star_index_dir: star_index_dir
      out_filter_multimap_nmax: out_filter_multimap_nmax
      star_threads: star_threads
    out:
      - aligned_bam
      - sj_tab
      - final_log
      - main_log
      - progress_log
      - stdout_log
      - stderr_log

outputs:
  - id: aligned_bams
    type: File[]
    label: "coordinate-sorted BAM files"
    doc: "One coordinate-sorted BAM per input FASTQ."
    outputSource: map_rnaseq/aligned_bam

  - id: sj_tabs
    type: File[]
    label: "splice junction tables"
    doc: "One SJ.out.tab per input FASTQ."
    outputSource: map_rnaseq/sj_tab

  - id: final_logs
    type: File[]
    label: "STAR final logs"
    doc: "One Log.final.out per input FASTQ, including unique-mapping rates."
    outputSource: map_rnaseq/final_log

  - id: main_logs
    type: File[]
    label: "STAR main logs"
    doc: "One Log.out per input FASTQ."
    outputSource: map_rnaseq/main_log

  - id: progress_logs
    type: File[]
    label: "STAR progress logs"
    doc: "One Log.progress.out per input FASTQ."
    outputSource: map_rnaseq/progress_log

  - id: stdout_logs
    type: File[]
    label: "stdout logs"
    doc: "stdout captured by cwltool for each scatter job."
    outputSource: map_rnaseq/stdout_log

  - id: stderr_logs
    type: File[]
    label: "stderr logs"
    doc: "stderr captured by cwltool for each scatter job."
    outputSource: map_rnaseq/stderr_log
