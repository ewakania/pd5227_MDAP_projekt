#!/bin/bash -ue
bwa index ref-SARS-CoV-2_Wuhan-Hu-1.fna
bwa mem ref-SARS-CoV-2_Wuhan-Hu-1.fna SRR23609084_trimmed_R1.fastq.gz SRR23609084_trimmed_R2.fastq.gz  | samtools view -b - > SRR23609084.bam
