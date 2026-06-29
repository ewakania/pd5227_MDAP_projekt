#!/bin/bash -ue
trimmomatic PE -threads 4         SRR23609083_1.fastq.gz SRR23609083_2.fastq.gz         SRR23609083_trimmed_R1.fastq.gz /dev/null         SRR23609083_trimmed_R2.fastq.gz /dev/null         LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
