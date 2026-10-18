#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool
label: "count reads per gene with featureCounts"
doc: |
  Count reads per gene from STAR BAMs with featureCounts (Subread 2.1.1).
  help: docker run --rm quay.io/biocontainers/subread:2.1.1--h577a1d6_0 featureCounts
  CommandLineTool pattern: https://www.commonwl.org/user_guide/05-command-line-tools/index.html

  Upstream: Workflow/star_mapping_se_scatter.cwl (unique mappers only, --outFilterMultimapNmax 1).
  All BAMs are passed to one featureCounts run, so the output has one count column per BAM.

  Settings follow Iwakiri et al. RNA 2023 (rna.079469.122): -s 2 -t exon -g gene_id.
  -s 2 is reversely stranded, matching TruSeq Stranded single-end libraries.
  -p is not set because the reads are single-end.
  -M is not set; STAR already dropped multimapping reads.

baseCommand: [featureCounts]

arguments:
  - -a
  - $(inputs.annotation_gtf.path)
  - -o
  - $(inputs.output_counts_name)
  - -t
  - $(inputs.feature_type)
  - -g
  - $(inputs.attribute_type)
  - -s
  - $(inputs.strandness)
  - -T
  - $(inputs.threads)
  - --verbose

inputs:
  - id: aligned_bams
    type: File[]
    label: "STAR coordinate-sorted BAMs"
    doc: "BAM files to count. Each BAM becomes one column in the counts table, in this order."
    inputBinding:
      position: 1

  - id: annotation_gtf
    type: File
    label: "GENCODE GTF annotation"
    doc: "Same GTF used to build the STAR index (Tools/star_index.cwl)."
    default:
      class: File
      location: ../Data/GENCODE_v49/gencode.v49.annotation.gtf

  - id: output_counts_name
    type: string
    label: "counts table filename"
    doc: "Passed to -o. featureCounts also writes <name>.summary next to it."

  - id: feature_type
    type: string
    label: "feature type (-t)"
    doc: "GTF feature rows used for counting. exon follows the paper."
    default: exon

  - id: attribute_type
    type: string
    label: "attribute type (-g)"
    doc: "GTF attribute that groups features into genes. gene_id follows the paper."
    default: gene_id

  - id: strandness
    type: int
    label: "strandness (-s)"
    doc: |
      0 unstranded, 1 stranded, 2 reversely stranded. 2 matches TruSeq Stranded single-end.
      Iwakiri et al. RNA 2023 used featureCounts -s 2 with TruSeq stranded mRNA libraries:
        https://rnajournal.cshlp.org/content/early/2022/11/16/rna.079469.122
      TruSeq Stranded (dUTP) Read 1 maps to the antisense strand of the RNA:
        https://support.illumina.com/content/dam/illumina-support/documents/documentation/chemistry_documentation/samplepreps_truseq/truseq-stranded-mrna-workflow/truseq-stranded-mrna-workflow-reference-1000000040498-00.pdf
        https://knowledge.illumina.com/library-preparation/rna-library-prep/library-preparation-rna-library-prep-reference_material-list/000002238
      featureCounts uses -s 2 for reversely stranded reads:
        https://subread.sourceforge.net/featureCounts.html
        https://support.bioconductor.org/p/90581/
      Single-end reverse (SR) corresponds to featureCounts Reverse (2):
        https://artbio.github.io/startbio/bulk_RNAseq-IOC/16_strandness/
    default: 2

  - id: threads
    type: int
    label: "threads (-T)"
    doc: "CPU threads for featureCounts."
    default: 18

stdout: $(inputs.output_counts_name).stdout.log
stderr: $(inputs.output_counts_name).stderr.log

outputs:
  - id: counts_table
    type: File
    label: "gene counts table"
    doc: "Tab-delimited gene counts: gene annotation columns followed by one count column per BAM."
    outputBinding:
      glob: $(inputs.output_counts_name)

  - id: counts_summary
    type: File
    label: "counting summary"
    doc: "Assigned and unassigned read totals per BAM, for QC of each sample."
    outputBinding:
      glob: $(inputs.output_counts_name).summary

  - id: stdout_log
    type: File
    label: "stdout log"
    doc: "stdout captured by cwltool, including the featureCounts run report."
    outputBinding:
      glob: $(inputs.output_counts_name).stdout.log

  - id: stderr_log
    type: File
    label: "stderr log"
    doc: "stderr captured by cwltool, including the Docker platform warning."
    outputBinding:
      glob: $(inputs.output_counts_name).stderr.log

hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/subread:2.1.1--h577a1d6_0
