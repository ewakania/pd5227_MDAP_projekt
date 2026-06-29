#!/bin/bash -ue
bcftools mpileup -f ref-SARS-CoV-2_Wuhan-Hu-1.fna SRR23609084_sorted.bam | bcftools call -mv -Oz -o SRR23609084.vcf.gz
bcftools index SRR23609084.vcf.gz
