#!/bin/bash

# Define input directory
inputdirectory="/Users/nguyenminhthao/Documents/gut_microbiome/data/long"

# Define the number of reads to sample per file
NUM_SAMPLES=50000  # Recommended starting point

# Loop through all FASTQ files in the long/ folder
for file in "$inputdirectory/"*.fastq.gz; do
    # Extract sample ID
    SAMPLE_ID=$(basename "$file" .fastq.gz)

    echo " Starting ultra-fast assembly for a portion of $SAMPLE_ID..."

    # Create assembly directory
    ASSEMBLY_DIR="$inputdirectory/$SAMPLE_ID/assembly"
    mkdir -p "$ASSEMBLY_DIR"

    # Define the output file for the sampled reads
    SAMPLED_FILE="$ASSEMBLY_DIR/${SAMPLE_ID}.sampled.fastq.gz"

    echo " Sampling $NUM_SAMPLES reads from $file..."
    # Subsample the reads using seqtk
    gzcat "$file" | seqtk sample - $NUM_SAMPLES | gzip > "$SAMPLED_FILE"

    # Check if sampling was successful (basic check - file exists)
    if [[ ! -f "$SAMPLED_FILE" ]]; then
        echo " Sampling failed for $SAMPLE_ID!"
        continue
    fi

    echo " Starting Flye assembly on the sampled reads..."
    # Run Flye with speed-optimized settings on the sampled data
    flye --nano-raw "$SAMPLED_FILE" --out-dir "$ASSEMBLY_DIR" -i 1 --meta --threads 2

    # Check if Flye finished successfully
    if [[ ! -f "$ASSEMBLY_DIR/assembly.fasta" ]]; then
        echo " Assembly failed for $SAMPLE_ID!"
        continue
    fi

    # Rename and compress the assembled contigs
    mv "$ASSEMBLY_DIR/assembly.fasta" "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta"
    bgzip "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta"

    # Remove Flye temp files and the sampled file to save space
    rm -rf "$ASSEMBLY_DIR/params.json" "$ASSEMBLY_DIR/logs" "$ASSEMBLY_DIR/iterations" \
           "$ASSEMBLY_DIR/assembly_graph*" "$ASSEMBLY_DIR/contigs_info.txt" "$SAMPLED_FILE"

    # Run MetaQUAST (on the assembly of the sampled data)
    metaquast.py --threads 1 --min-contig 500 --no-plots --max-ref-number 0 \
        --no-check --no-snps --silent -l "$SAMPLE_ID" \
        "$ASSEMBLY_DIR/${SAMPLE_ID}.contigs.fasta.gz" -o "$ASSEMBLY_DIR/qc"

    echo " Completed assembly of sampled reads for $SAMPLE_ID! Results in $ASSEMBLY_DIR"
done

echo " All assemblies of sampled reads completed!"