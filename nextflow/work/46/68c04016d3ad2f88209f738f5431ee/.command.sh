#!/bin/bash -ue
trimmomatic PE -threads 4         SRR23609084_1.fastq.gz SRR23609084_2.fastq.gz         SRR23609084_trimmed_R1.fastq.gz /dev/null         SRR23609084_trimmed_R2.fastq.gz /dev/null         LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
