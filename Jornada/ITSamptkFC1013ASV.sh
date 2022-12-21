#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 16 --mem 128G -J  NPDec2018Fungi --time 08:00:00
CPU=$SLURM_CPUS_ON_NODE

if [ ! $CPU ]; then
 CPU=2
fi

hostname
module load amptk
BASE=FC1013ASV
INPUT=illumina

if [ ! -f $BASE.demux.fq.gz ]; then
 amptk illumina -i $INPUT --merge_method vsearch -f ITS1-F -r ITS2 --require_primer off -o $BASE --usearch usearch9 --cpus $CPU --rescue_forward on --primer_mismatch 2 -l 300
fi

if [ ! -f $BASE.otu_table.txt ];  then
 amptk dada2 -i $BASE.demux.fq.gz -o $BASE --uchime_ref ITS --platform illumina -e 0.9
fi

if [ ! -f $BASE.filtered.otus.fa ]; then
 amptk filter -i $BASE.otu_table.txt -f $BASE.ASVs.fa -p 0.005
fi

if [ ! -f $BASE.otu_table.taxonomy.txt ]; then
 amptk taxonomy -f $BASE.filtered.otus.fa -i $BASE.final.txt -d ITS
fi

if [ ! -f $BASE.guilds.txt ]; then
 amptk funguild -i $BASE.otu_table.taxonomy.txt --db fungi -o $BASE
fi

if [ ! -f $BASE.taxonomy.fix.txt ]; then
 perl rdp_taxonmy2mat.pl<$BASE.taxonomy.txt>$BASE.taxonomy.fix.txt
fi

