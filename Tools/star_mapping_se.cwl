#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "map single-end RNA-seq with STAR"
doc: |
  Map trimmed single-end RNA-seq FASTQ with STAR 2.7.11b.
  help: docker run --rm quay.io/biocontainers/star:2.7.11b--h5ca1c30_8 STAR --help
  CommandLineTool pattern: https://www.commonwl.org/user_guide/05-command-line-tools/index.html

  Intended reads: PRJDB9451 (50 bp) and PRJDB12380 (36 bp).
  Both are TruSeq Stranded single-end. The index is built with --sjdbOverhang 49.
  Do not pass --sjdbOverhang at mapping time; STAR reuses the value stored in the index.

  --alignEndsType is omitted so STAR keeps the default Local (soft-clipping allowed).
  Extend5pOfRead1 is a CAGE-seq setting and is not used for RNA-seq.

  --quantMode is omitted. Gene counts are made later with featureCounts (-s 2),
  matching Iwakiri et al. RNA 2023 (rna.079469.122).
  --outFilterMultimapNmax 1 keeps only uniquely mapped reads, as in that paper.
  Reads that map to two or more loci are dropped and counted as "mapped to too many loci".

  rRNA is not filtered in a separate STAR pass. Reads from rRNA host genes would be
  removed together with rRNA repeats.

  Library strandedness does not change alignment scoring. STAR has no bulk-RNA-seq
  option equivalent to HISAT2 --rna-strandness. These strand options were checked
  and left unset:
  --outFilterIntronStrands RemoveInconsistentStrands is already the default. It drops
  spliced alignments whose donor/acceptor motifs disagree, independent of the kit.
  --outSAMstrandField intronMotif would also drop non-canonical junctions to set a
  Cufflinks XS tag, so it is not a stranded-library accuracy option.
  --soloStrand applies only to STARsolo.

baseCommand: [STAR]

arguments:
  - --genomeDir
  - $(inputs.star_index_dir.path)
  - --readFilesCommand
  - zcat
  - --readFilesIn
  - $(inputs.rnaseq_read.path)
  - --runThreadN
  - $(inputs.star_threads)
  - --outSAMtype
  - BAM
  - SortedByCoordinate
  - --outFilterMultimapNmax
  - $(inputs.out_filter_multimap_nmax)
  - --outFileNamePrefix
  - $(inputs.rnaseq_read.nameroot)_

inputs:
  - id: star_index_dir
    type: Directory
    label: "STAR index directory"
    doc: "Genome index from Tools/star_index.cwl (sjdbOverhang 49)."

  - id: rnaseq_read
    type: File
    label: "trimmed single-end RNA-seq FASTQ"
    doc: "Gzip-compressed FASTQ already trimmed by fastp. Read with zcat."

  - id: out_filter_multimap_nmax
    type: int
    label: "outFilterMultimapNmax"
    doc: |
      Maximum number of loci reported for one read.
      Default 1 follows Iwakiri et al.: alignments are written only when the read
      maps to a single locus. STAR's own default is 10.
    default: 1

  - id: star_threads
    type: int
    label: "threads for STAR"
    doc: "CPU threads for STAR mapping (--runThreadN)."
    default: 18

stdout: $(inputs.rnaseq_read.nameroot)_stdout.log
stderr: $(inputs.rnaseq_read.nameroot)_stderr.log

outputs:
  - id: aligned_bam
    type: File
    label: "coordinate-sorted BAM"
    doc: "STAR alignments sorted by coordinate (--outSAMtype BAM SortedByCoordinate)."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_Aligned.sortedByCoord.out.bam

  - id: sj_tab
    type: File
    label: "splice junctions"
    doc: "High-confidence splice junctions reported by STAR (SJ.out.tab)."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_SJ.out.tab

  - id: final_log
    type: File
    label: "STAR final log"
    doc: "Mapping summary, including uniquely mapped and multimapping rates (Log.final.out)."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_Log.final.out

  - id: main_log
    type: File
    label: "STAR main log"
    doc: "Run parameters and runtime messages (Log.out)."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_Log.out

  - id: progress_log
    type: File
    label: "STAR progress log"
    doc: "Progress counters written while mapping (Log.progress.out)."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_Log.progress.out

  - id: stdout_log
    type: File
    label: "stdout log"
    doc: "stdout captured by cwltool."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_stdout.log

  - id: stderr_log
    type: File
    label: "stderr log"
    doc: "stderr captured by cwltool, including STAR warnings."
    outputBinding:
      glob: $(inputs.rnaseq_read.nameroot)_stderr.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/star:2.7.11b--h5ca1c30_8
