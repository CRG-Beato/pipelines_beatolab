#!/bin/bash
#$ -N chipseq_call_peaks_20151110_peak_calling_T_0_PR_MCF_7_11728_ACAGTG
#$ -q short-sl65
#$ -l virtual_free=40G
#$ -l h_rt=06:00:00
#$ -o /users/GR/mb/jquilez/pipelines/chipseq_call_peaks/20151110/job_out/chipseq_call_peaks_20151110_peak_calling_T_0_PR_MCF_7_11728_ACAGTG_$JOB_ID.out
#$ -e /users/GR/mb/jquilez/pipelines/chipseq_call_peaks/20151110/job_out/chipseq_call_peaks_20151110_peak_calling_T_0_PR_MCF_7_11728_ACAGTG_$JOB_ID.err
#$ -M javier.quilez@crg.eu
#$ -m ae
#$ -pe smp 1
/software/mb/bin/macs2 callpeak -t /users/GR/mb/jquilez/data/chipseq/samples/T_0_PR_MCF_7_11728_ACAGTG/alignments/bowtie/T_0_PR_MCF_7_11728_ACAGTG_sorted.bam -n T_0_PR_MCF_7_11728_ACAGTG --outdir /users/GR/mb/jquilez/data/chipseq/samples/T_0_PR_MCF_7_11728_ACAGTG/peaks/macs2 -g hs -B --call-summits --verbose 3
