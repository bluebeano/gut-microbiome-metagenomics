#!/bin/bash

# Define input and reference genome paths
inputdirectory="/Users/nguyenminhthao/Documents/gut_microbiome/data"
hg38="$inputdirectory/ref/hg38.fa"

# Create necessary output directories
mkdir -p "$inputdirectory/long/trimmed"
mkdir -p "$inputdirectory/long/remove_host"
mkdir -p "$inputdirectory/long/qc"

# Process each long-read FASTQ file
for sample in "$inputdirectory/long/"*.fastq.gz; do
    SAMPLE_ID=$(basename "$sample" .fastq.gz)

    echo "Processing $SAMPLE_ID..."
    
    # Adapter trimming
    porechop -i "$sample" -t 4 -o "$inputdirectory/long/trimmed/${SAMPLE_ID}.porechop.fastq"

    # Align with host reference genome
    minimap2 -t 4 -ax map-ont -m 50 --secondary=no "$hg38" \
        "$inputdirectory/long/trimmed/${SAMPLE_ID}.porechop.fastq" | \
        samtools sort -@ 4 -o "$inputdirectory/long/${SAMPLE_ID}.sorted.bam"

    # Remove original trimmed fastq to save space
    rm "$inputdirectory/long/trimmed/${SAMPLE_ID}.porechop.fastq"

    # Get unmapped reads & convert sorted BAM to unmapped BAM
    samtools view -@ 4 -b -f 4 "$inputdirectory/long/${SAMPLE_ID}.sorted.bam" | \
        samtools fastq -@ 4 -T '*' | bgzip -@ 4 > "$inputdirectory/long/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"

    # Remove intermediate BAM file to free storage
    rm "$inputdirectory/long/${SAMPLE_ID}.sorted.bam"

    # Create QC directory for this sample
    QC_DIR="$inputdirectory/long/qc/$SAMPLE_ID"
    mkdir -p "$QC_DIR"

    # Run NanoPlot with organized output
    NanoPlot -t 4 -o "$QC_DIR" -c darkblue --title "$SAMPLE_ID" \
        --fastq "$inputdirectory/long/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"

    echo " Completed QC for $SAMPLE_ID → Results in $QC_DIR"
done

echo " All long-read samples processed!"
