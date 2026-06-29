#!/bin/bash -ue
bcftools merge SRR23609079.vcf.gz SRR23609080.vcf.gz SRR23609083.vcf.gz SRR23609085.vcf.gz SRR23609077.vcf.gz SRR23609084.vcf.gz SRR23609081.vcf.gz SRR23609078.vcf.gz SRR23609086.vcf.gz SRR23609082.vcf.gz -Oz -o merged.vcf.gz
bcftools view merged.vcf.gz > merged.vcf
bcftools stats merged.vcf > stats.txt
