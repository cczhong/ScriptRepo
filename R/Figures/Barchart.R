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
data<-read.table(opt$file, sep="\t", header=TRUE, row.names=1)
data_m<-as.matrix(data)
data_m<-data.matrix(data_m)

foo = rep("", ncol(data_m))
dataCName = colnames(data_m)
colnames(data_m) = foo


postscript(file=opt$out, onefile=FALSE, horizontal=FALSE, width=12, height=8)
par(pin=c(6,4))

par(mar = c(4, 4, 0.5, 8))
barplot(data_m, 
        col=rainbow(nrow(data_m)),
        main = "",
        ylab= "Num. of mutations",
        xlab= foo, space=1
)
end_point = 0.5 + ncol(data_m) + ncol(data_m)-1 #this is the line which does the trick (together with barplot "space = 1" parameter)
text(seq(1.5,end_point,by=2), par("usr")[3]-0.25, 
     srt = 60, adj= 1, xpd = TRUE,
     labels = paste(dataCName), cex=0.65)
usr <- par("usr")
x <- usr[2] * 1.02
y <- usr[4] * 0.6
legend(x, y, xpd = TRUE, 
       rownames(data_m), pch=rep(15, nrow(data_m)), 
       pt.cex = 1,
       col=rainbow(nrow(data_m)), cex = 0.65)

