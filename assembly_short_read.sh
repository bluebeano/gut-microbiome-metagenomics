#!/bin/bash

# Define input directory
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead/short"
# Define output directory for assembly results
output_root="$inputdirectory/assembly"
mkdir -p "$output_root"

# --- Configuration for your system ---
SPADES_THREADS=8  # Adjust based on your CPU core count. 8 is a good starting point.
QUAST_THREADS=4   # Adjust based on your CPU core count.
# ------------------------------------

# Activate the environment (assuming it's named 'long_read_shotgun')
if [[ -n "$(conda env list | grep long_read_shotgun)" ]]; then
    echo " Activating conda environment: long_read_shotgun"
    source activate long_read_shotgun
elif [[ -n "$(mamba env list | grep long_read_shotgun)" ]]; then
    echo " Activating mamba environment: long_read_shotgun"
    source activate long_read_shotgun # mamba uses the same activate command
else
    echo " Environment 'long_read_shotgun' not found. Ensure it is activated."
    exit 1
fi

# Find all forward reads and process them
find "$inputdirectory" -maxdepth 1 -name "*_1.fastq.gz" | sort | while IFS= read -r read1; do
    # Extract the sample ID from the forward read filename
    SAMPLE_ID=$(basename "$read1" | sed 's/_1.fastq.gz//')

    # Define the corresponding reverse read filename
    read2="${read1/_1.fastq.gz/_2.fastq.gz}"

    # Define the output directory for this sample
    OUTPUT_DIR="$output_root/${SAMPLE_ID}"
    mkdir -p "$OUTPUT_DIR"

    # Check if the reverse read file exists
    if [ -f "$read2" ]; then
        echo " Processing sample: ${SAMPLE_ID}"
        echo " Running MetaSPAdes for sample: ${SAMPLE_ID}"

        # Run MetaSPAdes with paired-end reads and specified threads
        metaspades.py --threads "$SPADES_THREADS" -1 "$read1" -2 "$read2" -o "$OUTPUT_DIR"

        # Check if the assembly was successful
        if [[ $? -ne 0 ]]; then
            echo "Error: MetaSPAdes failed for sample ${SAMPLE_ID}"
            continue
        fi
        echo " MetaSPAdes assembly completed successfully for sample ${SAMPLE_ID}"

        # Move assembly results to appropriate names and compress files
        mv "${OUTPUT_DIR}/assembly_graph_with_scaffolds.gfa" "${OUTPUT_DIR}/${SAMPLE_ID}.gfa"
        mv "${OUTPUT_DIR}/scaffolds.fasta" "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta"
        mv "${OUTPUT_DIR}/contigs.fasta" "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta"
        mv "${OUTPUT_DIR}/spades.log" "${OUTPUT_DIR}/${SAMPLE_ID}.log"

        # Compress the result files
        gzip "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta"
        gzip "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta"

        # Create QC directories
        mkdir -p "${OUTPUT_DIR}/qc/contigs"
        mkdir -p "${OUTPUT_DIR}/qc/scaffolds"

        echo " Running MetaQUAST on contigs for sample: ${SAMPLE_ID}"
        # Run MetaQUAST on the compressed contigs file with specified threads
        metaquast.py --threads "$QUAST_THREADS" --rna-finding --max-ref-number 0 -l "${SAMPLE_ID}" \
                     "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta.gz" -o "${OUTPUT_DIR}/qc/contigs"

        echo " Running MetaQUAST on scaffolds for sample: ${SAMPLE_ID}"
        # Run MetaQUAST on the compressed scaffolds file with specified threads
        metaquast.py --threads "$QUAST_THREADS" --rna-finding --max-ref-number 0 -l "${SAMPLE_ID}" \
                     "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta.gz" -o "${OUTPUT_DIR}/qc/scaffolds"
    else
        echo " Warning: Paired-end file not found for sample ${SAMPLE_ID} (read2: $read2). Skipping."
    fi
done

echo " Short-read assembly and QC completed."