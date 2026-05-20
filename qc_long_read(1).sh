#!/bin/bash

# Define input and reference genome paths
inputdirectory="/Users/nguyenminhthao/Documents/gut_microbiome/data"
hg38="$inputdirectory/ref/hg38.fa"
hg38_index="$inputdirectory/ref/hg38.mmi"

# Create necessary output directories
mkdir -p "$inputdirectory/long/remove_host"
mkdir -p "$inputdirectory/long/qc"

# Step 1: Pre-build Minimap2 index (only if it doesn’t exist)
if [ ! -f "$hg38_index" ]; then
    echo " Pre-building Minimap2 index for $hg38..."
    minimap2 -d "$hg38_index" "$hg38"
    echo " Minimap2 index built: $hg38_index"
else
    echo " Minimap2 index already exists: $hg38_index"
fi

# Step 2: Process each long-read FASTQ file
for sample in "$inputdirectory/long/"*.fastq.gz; do
    SAMPLE_ID=$(basename "$sample" .fastq.gz)

    echo " Processing $SAMPLE_ID..."
    
    # Align with pre-built Minimap2 index (optimized for 8GB RAM)
    minimap2 -t 6 -ax map-ont -m 50 --secondary=no -K 2G -I 3G "$hg38_index" "$sample" | \
        samtools sort -@ 6 --output-fmt BAM,level=1 -o "$inputdirectory/long/${SAMPLE_ID}.sorted.bam"

    # Get unmapped reads & convert to FASTQ format (optimized for storage)
    samtools view -@ 6 -b -f 4 "$inputdirectory/long/${SAMPLE_ID}.sorted.bam" | \
        samtools fastq -@ 6 -T '*' | bgzip -@ 6 > "$inputdirectory/long/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"

    # Remove intermediate BAM files to save space
    rm "$inputdirectory/long/${SAMPLE_ID}.sorted.bam"

    # Quality control using NanoPlot (uses minimal resources)
    NanoPlot -t 4 -p filtered -c darkblue --title "$SAMPLE_ID" \
        --fastq "$inputdirectory/long/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"
    
    echo " Completed QC for $SAMPLE_ID"
done

echo " All long-read samples processed!"
