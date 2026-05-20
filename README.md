# Metagenomic Pipeline (Short and Long Reads)

This repository contains the shell scripts I wrote to process a hybrid gut microbiome dataset, combining Illumina short-reads and Oxford Nanopore long-reads. 

I used the human reference genome (hg38) to filter out host DNA contamination, and tested the pipeline using the public dataset from this paper:
Chen, L., Zhao, N., Cao, J. et al. Short- and long-read metagenomics expand individualized structural variations in gut microbiomes. Nat Commun 13, 3175 (2022).

---

## Script List and Workflow

1. Data Setup
- download_data.sh: Pulls the raw data from the public repository.
- convert_to_fastq.sh: Converts the raw download formats into standard FASTQ files.

2. QC and Host Filtering (hg38 removal)
- qc_short_read.sh and qc_short_read(0).sh: Cleans up short-reads using fastp and checks quality with FastQC. Then it maps the reads against hg38 using Bowtie2 to drop the human DNA.
- qc_long_read.sh, (0), and (1): Handles the Nanopore long-reads using Porechop for adapters and NanoPlot for stats. Uses Minimap2 to align against hg38 and filter out host reads.

3. De Novo Assembly
- assembly_short_read.sh: Assembles the clean short-reads into contigs using MEGAHIT.
- assembly_long_read.sh and assembly_long_read(0).sh: Runs Flye on the long-reads to help resolve repetitive regions and structural variants that short reads miss.

4. Taxonomy and Profiling
- kraken2.sh: Runs a k-mer search to assign taxonomic labels to the sequences.
- bracken.sh: Takes the Kraken2 output and estimates relative species abundance.

---

## Tools Used
- QC and Alignment: Porechop, fastp, Minimap2, Bowtie2, FastQC, NanoPlot
- Assemblers: Flye, MEGAHIT
- Taxonomy: Kraken2, Bracken
- Reference: Human Genome Build 38 (hg38.fa)
