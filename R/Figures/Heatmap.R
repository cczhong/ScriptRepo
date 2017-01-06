#!/usr/bin/env Rscript
library("optparse")
library("gplots")

# the input file is a tab-delimited file with the first row as the column names
# and the first column as the row names, the script will produce hierachical clustering
# both row-wise and column-wise, with row-wise normalization

# inputing arguments
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file name", metavar="character"),
  make_option(c("-o", "--out"), type="character", default="figure.eps", 
              help="output file name [default= %default]", metavar="character"),
  make_option(c("-c", "--col_font_size"), type="double", default=0.6, 
              help="column name font size [default= %default]", metavar="numeric"),
  make_option(c("-r", "--row_font_size"), type="double", default=0.6, 
              help="row name font size [default= %default]", metavar="numeric")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}

# loading the data
data<-read.table(opt$file, header=TRUE, row.names=1)
data_m<-as.matrix(data)
data_m<-data.matrix(data_m)

# check if some rows are all 0s
take<-rep(FALSE, dim(data_m)[1])
for(i in c(1:dim(data_m)[1])) {
  is_valid<-FALSE
  for(j in c(1:dim(data_m)[2])) {
    if(data_m[i,j] > 0)  {
      is_valid<-TRUE
      take[i]<-is_valid
      next
    }
  }
}
data_m<-data_m[take,]

# define colors
new_vermillion = rgb(213, 94, 0, maxColorValue=255)
new_blue = rgb(0, 114, 178, maxColorValue=255)
my_palette <- colorRampPalette(c("green", "black", "red"))(n = 299)

postscript(file=opt$out, onefile=FALSE, horizontal=FALSE, width=8, height=12)
par(pin=c(6,4),cex.main=3)

heatmap.2(
  data_m, col=my_palette, trace="none", density="none", scale="row", 
  cexRow=opt$row_font_size, cexCol=opt$col_font_size,
  margin=c(10,10), srtCol=270, adjCol=c(0,NA),
  dendrogram="both", Rowv=TRUE, Colv=TRUE,
  hclust=function(x) hclust(x,method="mcquitty"),
  distfun=function(x) as.dist(1-cor(t(x), method="spearman"))
)
dev.off()
