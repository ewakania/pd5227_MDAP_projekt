#!/bin/bash -ue
bcftools mpileup -f ref-SARS-CoV-2_Wuhan-Hu-1.fna SRR23609080_sorted.bam | bcftools call -mv -Oz -o SRR23609080.vcf.gz
bcftools index SRR23609080.vcf.gz
