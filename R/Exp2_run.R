# steps recommended in https://benjjneb.github.io/dada2/tutorial.html
library(dada2)
library(phangorn)
library(phyloseq)
library(Biostrings)
library(ggplot2)
library(plyr)
library(msa)
theme_set(theme_bw())

# define data path 
data_path <- "/home/cczhong/Works/Microbiome_Kristina/Exp2"

# Forward and reverse fastq filenames have format: SAMPLENAME_R1_001.fastq and SAMPLENAME_R2_001.fastq
fnFs <- sort(list.files(data_path, pattern="_R1_001.fastq", full.names = TRUE))
fnRs <- sort(list.files(data_path, pattern="_R2_001.fastq", full.names = TRUE))

# Extract sample names, assuming filenames have format: SAMPLENAME_XXX.fastq
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)

# Place filtered files in filtered/ subdirectory
filtFs <- file.path(data_path, "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path(data_path, "filtered", paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

# Filter the data
filter_out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(240,160),
              maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
              compress=TRUE, multithread=TRUE)
#head(filter_out)

# Learn the error rates
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)

# Infer unique sequences
dadaFs <- dada(filtFs, err=errF, multithread=TRUE)
dadaRs <- dada(filtRs, err=errR, multithread=TRUE)

# Merge paired sequences
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)

# Construct sequence table
seqtab <- makeSequenceTable(mergers)

# Remove chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE, verbose=TRUE)

save.image("/home/cczhong/Works/Microbiome_Kristina/Exp2.RData")

# Assign taxonomy
taxa <- assignTaxonomy(seqtab.nochim, "/home/Database/SILVA/silva_nr_v132_train_set.fa.gz", multithread=TRUE)
taxa <- addSpecies(taxa, "/home/Database/SILVA/silva_species_assignment_v132.fa.gz")

# Construct phylogenetic tree from the inferred sequences using phangorn
seqs<- getSequences(seqtab)
names(seqs)<-seqs	# This propagates to the tip labels of the tree
mult<- msa(seqs,method="ClustalW",type="dna",order="input")
phang.align<- as.phyDat(mult,type="DNA",names=getSequence(seqtab))
dm<- dist.ml(phang.align)
treeNJ<- NJ(dm)
fit= pml(treeNJ,data=phang.align)

fitGTR<- update(fit,k=4,inv=0.2)
fitGTR<- optim.pml(fitGTR,model="GTR",optInv=TRUE,optGamma=TRUE,rearrangement="stochastic",control=pml.control(trace=0))
#detach("package:phangorn",unload=TRUE)

save.image("/home/cczhong/Works/Microbiome_Kristina/Exp2.RData")

# Connection with PhyloSeq
# set the sample variables
subject <- rownames(seqtab.nochim)
g_table<-read.table("/home/cczhong/Works/Microbiome_Kristina/Exp2/group")
ID<-match(subject, g_table$V1)
ID<-na.omit(ID)
stopifnot(length(ID) == dim(g_table)[1])	# check if the ID and group definition match
group<-g_table[ID,2]
samdf<-data.frame(Subject=subject, Group=group)
rownames(samdf)<-rownames(seqtab.nochim)

# define the PhyloSeq object
ps <- phyloseq(
	otu_table(seqtab.nochim, taxa_are_rows=FALSE), 
	sample_data(samdf), 
	tax_table(taxa),
	phy_tree(fitGTR$tree)
)
#ps <- subset_taxa(ps, Genus != "-1")

# now plot figures
# alpha diversity
pdf(file="/home/cczhong/Works/Microbiome_Kristina/alpha_diversity.pdf", width=10, height=5)
p = plot_richness(ps, x="Group", color="Group")
p + geom_boxplot(data = p$data, aes(x = Group, y = value, color = NULL), alpha = 0.1)
dev.off()

# beta distance
pdf(file="/home/cczhong/Works/Microbiome_Kristina/bray_distance.pdf", width=5, height=5)
ps.prop <- transform_sample_counts(ps, function(otu) (otu + 1)/sum(otu + 1))
ord.nmds.bray <- ordinate(ps.prop, method="NMDS", distance="bray")
plot_ordination(ps.prop, ord.nmds.bray, color="Group", title="Bray NMDS")
dev.off()

# abundance barchart
pdf(file="/home/cczhong/Works/Microbiome_Kristina/abundance.pdf", width=6, height=4)
ps.known <- subset_taxa(ps, Genus != "-1")	# remove unknown taxa
top20 <- names(sort(taxa_sums(ps.known), decreasing=TRUE))[1:20]
ps.top20 <- transform_sample_counts(ps.known, function(OTU) OTU/sum(OTU))
ps.top20 <- prune_taxa(top20, ps.top20)
plot_bar(ps.top20, x="Subject", fill="Family") + facet_wrap(~Group, scales="free_x")
dev.off()

# phylogenetic tree and abundance
# rename DNA sequences to OTU
dna <- Biostrings::DNAStringSet(taxa_names(ps))	# dna stores the mapping of OTU ID and sequence
names(dna) <- taxa_names(ps)
ps <- merge_phyloseq(ps, dna)
taxa_names(ps) <- paste0(" OTU", seq(ntaxa(ps)))
ps1 <- prune_taxa(taxa_sums(ps) > 2, ps)	# filter out taxa with abundane <= 2
ps2 = tax_glom(ps1, taxrank = "Family")		# group families
ps3 = tip_glom(ps2, h=0.4)			# group tips
pdf(file="/home/cczhong/Works/Microbiome_Kristina/tree.pdf", width=6, height=6)
plot_tree(ps3,
	  size = "Abundance",
          color = "Group",
          #justify = "yes please",
	  label.tips = "taxa_names",
          ladderize = "left") + scale_size_continuous(range = c(1, 5)
)
dev.off()
write.table(dna, file="/home/cczhong/Works/Microbiome_Kristina/otu.csv")	# output the OTU table

