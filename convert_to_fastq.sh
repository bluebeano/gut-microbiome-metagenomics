#!/bin/bash

# Define base directories
BASE_DIR=~/Documents/gut_microbiome/data
LONG_READ_DIR="$BASE_DIR/long"
SHORT_READ_DIR="$BASE_DIR/short"
TEMP_DIR="$BASE_DIR/temp"  # Custom temporary directory

# Create temp directory if it doesn’t exist
mkdir -p "$TEMP_DIR"

# List of long-read samples
LONG_SAMPLES=(
    SRR18491298
    SRR18490946
)

# List of short-read samples
SHORT_SAMPLES=(
    SRR18490938
    SRR18491056
)

# Function to convert SRA to FASTQ with custom temp directory
convert_sra_to_fastq() {
    local sample_id=$1
    local input_dir=$2
    local output_dir=$2

    echo " Processing $sample_id in $input_dir..."
    
    if [ -f "$input_dir/${sample_id}.sra" ]; then
        echo " Converting $sample_id to FASTQ..."
        fasterq-dump "$input_dir/${sample_id}.sra" --threads 10 --temp "$TEMP_DIR" --outdir "$output_dir"

        echo " Done: $output_dir/${sample_id}.fastq"
    else
        echo " File not found: $input_dir/${sample_id}.sra"
    fi
}

# Convert long-read files
echo " Converting long-read SRA files..."
for SAMPLE in "${LONG_SAMPLES[@]}"; do
    convert_sra_to_fastq "$SAMPLE" "$LONG_READ_DIR"
done

# Convert short-read files (paired-end)
echo " Converting short-read SRA files..."
for SAMPLE in "${SHORT_SAMPLES[@]}"; do
    if [ -f "$SHORT_READ_DIR/${SAMPLE}.sra" ]; then
        echo " Converting paired-end reads for $SAMPLE..."
        fasterq-dump "$SHORT_READ_DIR/${SAMPLE}.sra" --split-files --threads 10 --temp "$TEMP_DIR" --outdir "$SHORT_READ_DIR"

        echo " Done: $SHORT_READ_DIR/${SAMPLE}_1.fastq & ${SAMPLE}_2.fastq"
    else
        echo " File not found: $SHORT_READ_DIR/${SAMPLE}.sra"
    fi
done

echo " All SRA files converted to FASTQ!"
