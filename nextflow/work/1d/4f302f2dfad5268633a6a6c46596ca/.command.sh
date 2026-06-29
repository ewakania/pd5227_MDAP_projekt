#!/bin/bash -ue
bcftools mpileup -f ref-SARS-CoV-2_Wuhan-Hu-1.fna SRR23609086_sorted.bam | bcftools call -mv -Oz -o SRR23609086.vcf.gz
bcftools index SRR23609086.vcf.gz
