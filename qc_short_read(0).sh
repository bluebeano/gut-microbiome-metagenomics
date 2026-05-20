#!/bin/bash

# Define input directory
inputdirectory="$HOME/Documents/gut_microbiome/data/short"
# Define host reference genome
hg38="$inputdirectory/hg38.fa"

# Process each paired-end Illumina short-read sample
for read1 in "$inputdirectory"/*_1.fastq.gz; do
    if [ -f "$read1" ]; then
        read2="${read1/_1.fastq.gz/_2.fastq.gz}"
        if [ -f "$read2" ]; then
            SAMPLE_ID=$(basename "$read1" | sed 's/_1.fastq.gz//')
            echo " Processing $SAMPLE_ID with input files: $read1 & $read2"

            # Create output directories
            trimmed_dir="$inputdirectory/${SAMPLE_ID}/trimmed"
            remove_host_dir="$inputdirectory/${SAMPLE_ID}/remove_host"
            fastqc_dir="$inputdirectory/${SAMPLE_ID}/fastqc"
            mkdir -p "$trimmed_dir" "$remove_host_dir" "$fastqc_dir"

            # Adapter trimming using fastp
            fastp \
                --in1 "$read1" \
                --in2 "$read2" \
                --out1 "$trimmed_dir/${SAMPLE_ID}_1.fastp.fastq.gz" \
                --out2 "$trimmed_dir/${SAMPLE_ID}_2.fastp.fastq.gz" \
                --json "$trimmed_dir/${SAMPLE_ID}_fastp.fastp.json" \
                --html "$trimmed_dir/${SAMPLE_ID}_fastp.fastp.html" \
                --thread 8 \
                --detect_adapter_for_pe \
                -q 15 --cut_front --cut_tail --cut_mean_quality 15 --length_required 15 \
                2> "$trimmed_dir/${SAMPLE_ID}_fastp.fastp.log"

            # Host removal using Bowtie2
            bowtie2 -p 8 \
                -x "$hg38" \
                -1 "$trimmed_dir/${SAMPLE_ID}_1.fastp.fastq.gz" \
                -2 "$trimmed_dir/${SAMPLE_ID}_2.fastp.fastq.gz" \
                --sensitive \
                --un-conc-gz "$remove_host_dir/${SAMPLE_ID}_host_removed.unmapped_%.fastq.gz" \
                --al-conc-gz "$remove_host_dir/${SAMPLE_ID}_host_removed.mapped_%.fastq.gz" \
                1> /dev/null \
                2> "$remove_host_dir/${SAMPLE_ID}_host_removed.bowtie2.log"

            # Remove host-mapped reads
            rm -f "$remove_host_dir/${SAMPLE_ID}_host_removed.mapped_*.fastq.gz"

            # Run FastQC on host-filtered reads
            fastqc --quiet --threads 4 --memory 4000 \
                -o "$fastqc_dir" \
                "$remove_host_dir/${SAMPLE_ID}_host_removed.unmapped_1.fastq.gz" \
                "$remove_host_dir/${SAMPLE_ID}_host_removed.unmapped_2.fastq.gz"

        else
            echo " Missing paired file for: $read1"
        fi
    fi
done

# Run MultiQC on all FastQC reports
multiqc_output="$inputdirectory/multiqc_report"
mkdir -p "$multiqc_output"
find "$inputdirectory" -name "*fastqc*.zip" -o -name "*fastqc*.html" | xargs multiqc -o "$multiqc_output" -p 2

echo " Short-read QC and host removal completed! MultiQC report saved in: $multiqc_output"