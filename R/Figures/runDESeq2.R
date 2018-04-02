library("DESeq2")
cts <- read.table("~/Works/HeLab/test.tab", header = TRUE, row.names = 1)
cts <- as.matrix(cts)
coldata <- read.table("~/Works/HeLab/design.tab", header = TRUE, row.names = 1)
dds <- DESeqDataSetFromMatrix(countData = cts,
                              colData = coldata,
                              design = ~ condition)
dds <- DESeq(dds)
res <- results(dds)
write.table(as.data.frame(res), sep="\t",
          file="condition_treated_results.csv")