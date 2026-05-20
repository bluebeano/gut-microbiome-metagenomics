#!/bin/bash

# Define input directory
inputdirectory="$HOME/Documents/gut_microbiome/data/short"

# Create output directories
multiqc_output="$inputdirectory/multiqc_report"
mkdir -p "$multiqc_output"

# Loop through all paired-end reads
for read1 in "$inputdirectory"/*_1.fastq.gz; do
    if [ -f "$read1" ]; then
        read2="${read1/_1.fastq.gz/_2.fastq.gz}"
        if [ -f "$read2" ]; then
            SAMPLE_ID=$(basename "$read1" | sed 's/_1.fastq.gz//')
            fastqc_dir="$inputdirectory/${SAMPLE_ID}/fastqc"
            mkdir -p "$fastqc_dir"

            echo " Running FastQC on: $SAMPLE_ID"
            # Optimized FastQC command for single sample
            fastqc --quiet --threads 6 --memory 4000 -o "$fastqc_dir" "$read1" "$read2"
        else
            echo " Missing paired file for: $read1"
        fi
    fi
done

# Run MultiQC
find "$inputdirectory" -name "*fastqc*.zip" -o -name "*fastqc*.html" -print0 | xargs -0 multiqc -o "$multiqc_output" -p 2

echo " Short-read QC completed! MultiQC report saved in: $multiqc_output"