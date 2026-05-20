#!/bin/bash

# Define input and reference genome paths
inputdirectory="/Users/nguyenminhthao/Documents/gut_microbiome/data"

# Step 1: Process each long-read FASTQ file
for sample in "$inputdirectory/long/"*.fastq.gz; do
    SAMPLE_ID=$(basename "$sample" .fastq.gz)

    # Create a unique QC output folder for this sample
    QC_DIR="$inputdirectory/long/qc/$SAMPLE_ID"
    mkdir -p "$QC_DIR"

    echo " Processing $SAMPLE_ID... (Skipping host removal)"

    # Run NanoPlot and ensure output goes into this sample’s folder
    NanoPlot -t 4 -o "$QC_DIR" -c darkblue --title "$SAMPLE_ID" --fastq "$sample"

    echo " Completed QC for $SAMPLE_ID → Results in $QC_DIR"
done

echo " All long-read samples processed!"
