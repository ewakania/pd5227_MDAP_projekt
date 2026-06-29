#!/bin/bash -ue
samtools coverage SRR23609079_sorted.bam SRR23609080_sorted.bam SRR23609083_sorted.bam SRR23609085_sorted.bam SRR23609077_sorted.bam SRR23609084_sorted.bam SRR23609081_sorted.bam SRR23609078_sorted.bam SRR23609086_sorted.bam SRR23609082_sorted.bam > genome_coverage.txt
