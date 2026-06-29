
params.outdir="output"
params.reference = "reference/ref-SARS-CoV-2_Wuhan-Hu-1.fna"
 

SAMPLES = ["SRR23609083", "SRR23609077", "SRR23609079", "SRR23609081", "SRR23609082", "SRR23609078", 
"SRR23609080", "SRR23609084", "SRR23609085", "SRR23609086"] //array for channel
READS = ["1", "2"]
//REF = "ref-SARS-CoV-2_Wuhan-Hu-1"


/*
process DOWNLOAD_READS {
    publishDir "${params.input}", mode: 'copy'
    tag "${sample}"
    
    input:
    val sample
    
    output:
    tuple val(sample), path("${sample}_1.fastq.gz"),
    path("${sample}_2.fastq.gz"), emit:reads
    
    script:
    """
    fasterq-dump ${sample}
    gzip ${sample}_1.fastq
    gzip ${sample}_2.fastq
    rm -f ${sample}_1.fastq ${sample}_2.fastq
    """
}
*/

process INDEX_GENOME {

    publishDir "reference", mode: 'copy'
    container "biocontainers/bwa:v0.7.17_cv1"

    input:
    path reference

    output:
    tuple path("*")

    script:

    """
    bwa index ${reference}
    """

}

process TRIMMOMATIC {

    container "quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2"
    publishDir "${params.outdir}/trimming", mode: "copy"

    input:
    tuple val(id), path(reads)

    output:
    tuple val(id),
          path("${id}_trimmed_R1.fastq.gz"),
          path("${id}_trimmed_R2.fastq.gz"), emit: trimmed

    script:
    """
    trimmomatic PE -threads 4 \
        ${reads[0]} ${reads[1]} \
        ${id}_trimmed_R1.fastq.gz /dev/null \
        ${id}_trimmed_R2.fastq.gz /dev/null \
        LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    """
}

process FASTQC {
    publishDir "${params.outdir}/fastqc", mode: 'copy'
    
    input:
    tuple val(id), path(fastq_trimmed_1), path(fastq_trimmed_2)

    output:
    path "*_fastqc.zip", emit: fastqc_zip
    path "*_fastqc.html", emit: fastqc_html

// emit naming the output

    script:
    """
    fastqc  -o . ${fastq_trimmed_1} ${fastq_trimmed_2}
    """
}

process MULTIQC {
    publishDir "${params.outdir}/multiqc", mode: 'copy'
    
    input:
    path fastqc_files
    
    output:
    path "multiqc_report.html" 
    
    script:
    """
    multiqc .
    """
    }
/*
process INDEX_GENOME {
    publishDir "${params.input}/reference", mode: 'copy'
    container "biocontainers/bwa:v0.7.17_cv1"
    
    input:
    path reference

    output:
    tuple path(reference), path("ref_bundle/*")

    script:
    """
    mkdir -p ref_bundle
    cp ${reference} ref_bundle/
    REF=\$(basename ${reference})
    bwa index ref_bundle/\$REF
    """
}
*/
process MAPPING {
    publishDir "${params.outdir}/mapped_reads", mode: 'copy'
    container "agrf/bwa-samtools:0.7.17.1.9"
    


    input:
    path reference
    path indexed_files
    tuple val(id), path(fastq_trimmed_1), path(fastq_trimmed_2)
    
   
    output:
    tuple val(id), path("${id}.bam")

    script:
    """
    bwa index ${reference}
    bwa mem ${reference} ${fastq_trimmed_1} ${fastq_trimmed_2}  | samtools view -b - > ${id}.bam
    """

}



process SAMTOOLS_SORT {
    publishDir "${params.outdir}/sorted_reads", mode: 'copy'
    container "quay.io/biocontainers/samtools:1.23.1--ha83d96e_0"
    
    input:
    tuple val(id), path(bam)
    
    output:
    tuple val(id), path("${id}_sorted.bam"), emit: sorted_bam
    
    script:
    """
    samtools sort -O bam -o ${id}_sorted.bam ${bam}
    """
}

process SAMTOOLS_INDEX{
    publishDir "${params.outdir}/sorted_reads", mode: 'copy'
    container "quay.io/biocontainers/samtools:1.23.1--ha83d96e_0"

    input:
    tuple val(id), path(sorted_bam)

    output:
    tuple val(id), path("${id}_*.bai"), emit: sorted_bai

    script:
    """
    samtools index ${sorted_bam}
    """
}

process CALCULATE_COVERAGE{
    publishDir "${params.outdir}/sorted_reads", mode: 'copy'
    container "quay.io/biocontainers/samtools:1.23.1--ha83d96e_0"
    
    input:
    path bams
    
    output:
    path "genome_coverage.txt"
    
    //list.join(' ') not channel operator
    script:
        """
        samtools coverage ${bams.join(' ')} > genome_coverage.txt
        """

}

process INDEX_FASTA {
    publishDir "reference", mode: 'copy'
    container "quay.io/biocontainers/samtools:1.23.1--ha83d96e_0"

    input:
    path reference

    output:
    tuple path("${reference}"), path("${reference}.fai")

    script:
    """
    samtools faidx ${reference}
    """
}

process VARIANTS_IDENTIFICATION {
    publishDir "${params.outdir}/results", mode: 'copy'
    container "quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0"

    input:
    tuple path(reference)
    tuple val(id), path(sorted_bam)
  
    
    output:
    tuple val(id), path("${id}.vcf.gz"), path("${id}.vcf.gz.csi"), emit: vcf
    
   
    
    script:
    """
    bcftools mpileup -f ${reference} ${sorted_bam} | bcftools call -mv -Oz -o ${id}.vcf.gz
    bcftools index ${id}.vcf.gz
    """


}

process MERGE_VCF {
    publishDir "${params.outdir}/results", mode: 'copy'
    container "quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0"

    input:
    path(vcf)
    path(index)


    output:
    path "merged.vcf"
    path "stats.txt"

    script:
    """

    bcftools merge ${vcf.join(' ')} -Oz -o merged.vcf.gz
    bcftools view merged.vcf.gz > merged.vcf
    bcftools stats merged.vcf > stats.txt
    """
}



workflow {
    //reads_ch = Channel.of(SAMPLES).flatten()
    //DOWNLOAD_READS(reads_ch)
    reads_ch = channel.fromSRA(SAMPLES)
    ref_ch = channel.value(file(params.reference))
    indexed_ref=INDEX_GENOME(ref_ch)

    trimmed=TRIMMOMATIC(reads_ch)
    //trimmed.view()
    FASTQC(trimmed)
    MULTIQC(FASTQC.out.fastqc_zip.collect())
    //indexed_ref = INDEX_GENOME(ref)
    //indexed_ref.view()
   
   
    bam=MAPPING(ref_ch, indexed_ref, trimmed)
    sorted_bam=SAMTOOLS_SORT(bam)
    SAMTOOLS_INDEX(sorted_bam)
    all_bams = sorted_bam.map{ id, bam -> bam }.collect()
    CALCULATE_COVERAGE(all_bams)
    INDEX_FASTA(ref_ch)
    variants = VARIANTS_IDENTIFICATION(ref_ch, sorted_bam)
    vcfs = variants.map { id, vcf, idx-> vcf }
    index_vcf =  variants.map { id, vcf, idx-> idx }
    MERGE_VCF(vcfs.collect(), index_vcf.collect())


}