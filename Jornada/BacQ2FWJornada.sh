#!/usr/bin/bash
#SBATCH --nodes 1
#SBATCH --ntasks 28
#SBATCH --mem 128G
#SBATCH --job-name="Q2FWJornadaBacLEsilva515806"
#SBATCH --time=1-18:00:00


#This current version of Qiime2 script for 16S(Bacteria) analysis.
#Qiime2 is installed on cluster locally in user bin (not module).
#It took approximately 20 hours for 74 samples to complete.
#Nat updated on 02/20/18

cd $SLURM_SUBMIT_DIR
source activate qiime2-2018.8
export LC_ALL=es_US.utf8

BASE=JornadaBacQ2FWLEsilva515806.V1
MANIFEST=Q2FWJornadaBacManifest.csv
META=Q2FWJornadaBacMetadata.tsv

#1. input data as QIIME 2 artifacts.
#We will use the forward reads for this project.

if [ ! -f $BASE.single-end-demux.qza ]; then
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path $MANIFEST \
  --output-path $BASE.single-end-demux.qza \
  --input-format SingleEndFastqManifestPhred33
fi

#2. Demultiplexing sequences results summary 

if [ ! -f $BASE.demux.qzv ]; then
qiime demux summarize \
  --i-data $BASE.single-end-demux.qza \
  --o-visualization $BASE.demux.qzv
fi

#3.Sequence quality control and feature table construction (DADA2)
#Set trim-left to 19 to remove primer

if [ ! -f $BASE.table-dada2.qza ]; then
qiime dada2 denoise-single \
 --i-demultiplexed-seqs $BASE.single-end-demux.qza \
 --p-trim-left 19 \
 --p-trunc-len 250 \
 --p-max-ee 2 \
 --o-representative-sequences $BASE.rep-seqs.qza \
 --o-table $BASE.table-dada2.qza \
 --o-denoising-stats $BASE.stats-dada2.qza \
 --p-n-threads 28
fi

if [ ! -f $BASE.table-dada2.qzv ]; then
qiime feature-table summarize \
 --i-table $BASE.table-dada2.qza \
 --o-visualization $BASE.table-dada2.qzv \
 --m-sample-metadata-file $META
fi

if [ ! -f $BASE.rep-seqs.qzv ]; then
qiime feature-table tabulate-seqs \
 --i-data $BASE.rep-seqs.qza \
 --o-visualization $BASE.rep-seqs.qzv
fi

if [ ! -f $BASE.stats-dada2.qzv ]; then
qiime metadata tabulate \
 --m-input-file $BASE.stats-dada2.qza \
 --o-visualization $BASE.stats-dada2.qzv
fi

#4. Assign Taxonomy

if [ ! -f $BASE.taxonomy.qza ]; then
qiime feature-classifier classify-sklearn \
 --i-classifier silva-132-99-515-806-nb-classifier.qza \
 --i-reads $BASE.rep-seqs.qza \
 --o-classification $BASE.taxonomy.qza
fi

#5.Create Taxonomy table

if [ ! -f $BASE.taxonomy-with-spaces/taxonomy.tsv ]; then 
qiime tools export \
 --input-path $BASE.taxonomy.qza \
 --output-path $BASE.taxonomy-with-spaces
fi

if [ ! -f $BASE.taxonomy-as-metadata.qzv ]; then
qiime metadata tabulate \
 --m-input-file $BASE.taxonomy-with-spaces/taxonomy.tsv \
 --o-visualization $BASE.taxonomy-as-metadata.qzv
fi

if [ ! -f $BASE.taxonomy-as-metadata/metadata.tsv ]; then
qiime tools export \
 --input-path $BASE.taxonomy-as-metadata.qzv \
 --output-path $BASE.taxonomy-as-metadata
fi

if [ ! -f $BASE.taxonomy-without-spaces.qza ]; then
qiime tools import \
 --type 'FeatureData[Taxonomy]' \
 --input-path $BASE.taxonomy-as-metadata/metadata.tsv \
 --output-path $BASE.taxonomy-without-spaces.qza
fi

if [ ! -f $BASE.taxonomy.qzv ]; then
qiime metadata tabulate \
 --m-input-file $BASE.taxonomy-without-spaces.qza \
 --o-visualization $BASE.taxonomy-without-spaces.qzv
fi

#6 Alignment and Tree

if [ ! -f $BASE.rep-seqs.NoMC.qza ]; then
qiime taxa filter-seqs \
 --i-sequences $BASE.rep-seqs.qza \
 --i-taxonomy $BASE.taxonomy-without-spaces.qza \
 --p-exclude mitochondria,chloroplast \
 --o-filtered-sequences $BASE.rep-seqs.NoMC.qza
fi  

if [ ! -f $BASE.aligned-rep-seqs.NoMC.qza ]; then
qiime alignment mafft \
 --i-sequences $BASE.rep-seqs.NoMC.qza \
 --o-alignment $BASE.aligned-rep-seqs.NoMC.qza
fi

if [ ! -f $BASE.masked-aligned-rep-seqs.NoMC.qza ];then
qiime alignment mask \
 --i-alignment $BASE.aligned-rep-seqs.NoMC.qza \
 --o-masked-alignment $BASE.masked-aligned-rep-seqs.NoMC.qza
fi

if [ ! -f $BASE.unrooted-tree.NoMC.qza ]; then
qiime phylogeny fasttree \
 --i-alignment $BASE.masked-aligned-rep-seqs.NoMC.qza \
 --o-tree $BASE.unrooted-tree.NoMC.qza
fi

if [ ! -f $BASE.rooted-tree.NoMC.qza ]; then
qiime phylogeny midpoint-root \
 --i-tree $BASE.unrooted-tree.NoMC.qza \
 --o-rooted-tree $BASE.rooted-tree.NoMC.qza
fi

if [ ! -f $BASE.ExportedDataNoMC/tree.nwk ]; then
qiime tools export \
 --input-path $BASE.rooted-tree.NoMC.qza \
 --output-path $BASE.ExportedDataNoMC
fi


#6. export taxonomy, otutable

if [ ! -f $BASE.ExportedDataNoMC/taxonomy.tsv ]; then
qiime tools export \
 --input-path $BASE.taxonomy-without-spaces.qza \
 --output-path $BASE.ExportedDataNoMC
fi

if [ ! -f $BASE.no-mito-chloro.table-dada2.qza ]; then
qiime taxa filter-table \
 --i-table $BASE.table-dada2.qza \
 --i-taxonomy $BASE.taxonomy-without-spaces.qza \
 --p-exclude mitochondria,chloroplast \
 --o-filtered-table $BASE.no-mito-chloro.table-dada2.qza
fi

if [ ! -f $BASE.ExportedDataNoMC/feature-table.biom ]; then
qiime tools export \
 --input-path $BASE.no-mito-chloro.table-dada2.qza \
 --output-path $BASE.ExportedDataNoMC
fi

if [ ! -f $BASE.ExportedDataNoMC/$BASE.otu_table.txt ]; then
 biom convert -i $BASE.ExportedDataNoMC/feature-table.biom -o $BASE.ExportedDataNoMC/$BASE.otu_table.txt --to-tsv
fi

if [ ! -f $BASE.ExportedDataNoMC/$BASE.otu_table.fix.txt ]; then
sed 's/#OTU/OTU/g' $BASE.ExportedDataNoMC/$BASE.otu_table.txt > $BASE.ExportedDataNoMC/$BASE.otu_table.fix.txt 
fi

if [ ! -f $BASE.ExportedDataNoMC/taxonomy.fix.tsv ]; then
sed '1s/Feature/OTU/' $BASE.ExportedDataNoMC/taxonomy.tsv > $BASE.ExportedDataNoMC/taxonomy.fix.tsv
fi
