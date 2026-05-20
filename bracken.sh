#!/bin/bash

source activate long_read_shotgun

KRAKEN2_DB="/Users/nguyenminhthao/Documents/gut_microbiome/krakendb/"
INPUT_DIR="/Users/nguyenminhthao/Documents/gut_microbiome/data/long/"
KRAKEN2_OUTPUT_DIR="${INPUT_DIR}/kraken2_results"
MPA_DIR="${INPUT_DIR}/taxonomy_mpa"

mkdir -p "$KRAKEN2_OUTPUT_DIR"

find "$INPUT_DIR" -type f -name "*.assembly.kraken2.report.txt" | while read -r SAMPLE; do
    SAMPLE_NAME=$(basename "$SAMPLE" .assembly.kraken2.report.txt)

    REPORT_KRAKEN2_FILE="$SAMPLE"
    REPORT_MPA_FILE="${KRAKEN2_OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2.mpa"

    python kreport2mpa.py -r "$REPORT_KRAKEN2_FILE" --display-header -o "$REPORT_MPA_FILE"

    for LEVEL in P C O F G S S1; do
        bracken \
            -d "$KRAKEN2_DB" \
            -i "$REPORT_KRAKEN2_FILE" \
            -o "${KRAKEN2_OUTPUT_DIR}/${SAMPLE_NAME}.assembly.bracken_${LEVEL}.txt" \
            -r 300 \
            -l "$LEVEL"
    done    
done

for LEVEL in P C O F G S S1; do
    combine_bracken_outputs.py \
        --files ${KRAKEN2_OUTPUT_DIR}/*.assembly.bracken_${LEVEL}.txt \
        --output "${KRAKEN2_OUTPUT_DIR}/long_short.contigs.bracken_${LEVEL}.txt"
done

mkdir -p "$MPA_DIR"

find "$KRAKEN2_OUTPUT_DIR" -type f -name "*.assembly.kraken2.mpa" | xargs cp -n -t "$MPA_DIR"

if ls "$MPA_DIR"/*.mpa 1> /dev/null 2>&1; then
    python combine_mpa.py -i "$MPA_DIR"/*.mpa --output "${KRAKEN2_OUTPUT_DIR}/long_short.contigs.kraken.txt"
else
    echo "No .mpa files found in $MPA_DIR. Skipping combination step."
fi

rm -rf "$MPA_DIR"
