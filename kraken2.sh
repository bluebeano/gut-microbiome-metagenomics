#!/bin/bash

# Set Kraken2 database path (consider using a smaller, custom database)
KRAKEN2_DB="$HOME/Documents/gut_microbiome/krakendb"

# Input directory where your fasta.gz files are located
INPUT_DIR="$HOME/Documents/gut_microbiome/data/long"

# Ensure the database and input directory exist
if [[ ! -d "$KRAKEN2_DB" ]]; then
    echo "Error: Kraken2 database not found at $KRAKEN2_DB"
    exit 1
fi
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory not found at $INPUT_DIR"
    exit 1
fi

# Find all .contigs.fasta.gz files and process them one by one
find "$INPUT_DIR" -type f -name "*.contigs.fasta.gz" | while read -r SAMPLE; do
    SAMPLE_NAME=$(basename "$SAMPLE" .contigs.fasta.gz)
    ORIGINAL_NAME=${SAMPLE_NAME%_contigs}

    OUTPUT_DIR="$(dirname "$SAMPLE")/kraken2_${SAMPLE_NAME}"
    OUTPUT_KRAKEN2_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2"
    REPORT_KRAKEN2_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2.report.txt"
    REPORT_MPA_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2.mpa"

    mkdir -p "$OUTPUT_DIR"

    echo "Running Kraken2 on $SAMPLE_NAME..."
    kraken2 --db "$KRAKEN2_DB" \
        --output "$OUTPUT_KRAKEN2_FILE" \
        --confidence 0.03 \
        --report "$REPORT_KRAKEN2_FILE" \
        --memory-mapping \
        --gzip-compressed \
        --threads 4 \
        "$SAMPLE"

    echo "Finished Kraken2 for $SAMPLE_NAME"
done
