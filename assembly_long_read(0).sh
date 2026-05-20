#!/bin/bash

# Define input directory
inputdirectory="/Users/nguyenminhthao/Documents/gut_microbiome/data/long"

# Create output directory if it doesn’t exist
mkdir -p "$inputdirectory"

# Loop through all FASTQ files in remove_host folder
for file in "$inputdirectory/remove_host/"*.rmhost.fastq.gz; do
    # Extract sample ID
    SAMPLE_ID=$(basename "$file" .rmhost.fastq.gz)

    echo " Starting assembly for $SAMPLE_ID..."

    # Create assembly directory
    ASSEMBLY_DIR="$inputdirectory/$SAMPLE_ID/assembly"
    mkdir -p "$ASSEMBLY_DIR"

    # Run Flye for assembly
    flye --nano-raw "$file" --out-dir "$ASSEMBLY_DIR" -i 10 --meta --threads 4

    # Check if Flye finished successfully
    if [[ ! -f "$ASSEMBLY_DIR/assembly.fasta" ]]; then
        echo " Assembly failed for $SAMPLE_ID!"
        continue
    fi

    # Rename and compress the assembled contigs
    mv "$ASSEMBLY_DIR/assembly.fasta" "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta"
    bgzip "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta"

    # Run MetaQUAST for quality assessment
    metaquast.py --threads 4 --rna-finding --max-ref-number 0 -l "$SAMPLE_ID" \
        "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta.gz" -o "$ASSEMBLY_DIR/qc"

    echo " Completed assembly for $SAMPLE_ID! Results in $ASSEMBLY_DIR"
done

echo " All ONT long-read assemblies completed!"
