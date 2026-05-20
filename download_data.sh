#!/bin/bash

# Define the base directory
BASE_DIR=~/Documents/gut_microbiome
DATA_DIR="$BASE_DIR/data"
LONG_READ_DIR="$DATA_DIR/long_short"
HG38_DIR="$DATA_DIR/ref"

# Create necessary directories
mkdir -p "$LONG_READ_DIR"
mkdir -p "$HG38_DIR"

# List of SRA sample IDs to download
SRA_LIST=(
    SRR18491298
    SRR18490946
    SRR18490938
    SRR18491056
)

echo " Step 1: Downloading SRA files..."
for SRA_ID in "${SRA_LIST[@]}"; do
    echo " Downloading $SRA_ID..."
    prefetch --max-size 50G --output-directory "$LONG_READ_DIR" "$SRA_ID"
done
echo " All SRA files downloaded!"

echo " Step 2: Converting SRA to FASTQ..."
for SRA_ID in "${SRA_LIST[@]}"; do
    echo " Converting $SRA_ID to FASTQ..."
    fasterq-dump --split-files --threads 4 --progress --outdir "$LONG_READ_DIR" "$LONG_READ_DIR/$SRA_ID"
    
    echo " Compressing $SRA_ID.fastq..."
    gzip "$LONG_READ_DIR/${SRA_ID}_1.fastq"
done
echo " FASTQ conversion completed!"

# Download and prepare the hg38 reference genome
echo " Step 3: Downloading hg38 reference genome..."
wget -O "$HG38_DIR/hg38.fa.gz" ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_44/GRCh38.p14.genome.fa.gz
gunzip "$HG38_DIR/hg38.fa.gz"
echo " hg38 genome downloaded and extracted!"

echo " All necessary files are now ready in $BASE_DIR!"
