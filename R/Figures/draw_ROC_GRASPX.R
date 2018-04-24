file <- "~/Works/GRASP2/Results/MarineAmphora2/perf2.summary"
# read the file
data = read.table(file, header=F)
data_dim = dim(data)
# define ranges
x_l = 0
x_r = 1
y_l = 0
y_r = 1
# define color-friendly settings
new_purple = rgb(204, 121, 167, maxColorValue=255)
new_vermillion = rgb(213, 94, 0, maxColorValue=255)
new_blue = rgb(0, 114, 178, maxColorValue=255)
new_yellow = rgb(240, 228, 66, maxColorValue=255)

# append extrapolsted values
ext = rep(0,15)
for(i in c(1,2,3,4,5))  {
  k = 3 * (i - 1) + 1;
  slope = (data[1,k] - data[2,k]) / data[2,k+1];
  ext[k] = data[1,k] + slope * data[1,k+1];
}
data_ext = rbind(ext,data);
data_ext = rbind(data_ext,c(0,1,0,0,1,0,0,1,0,0,1,0,0,1,0))

# drawing the plots
postscript(file="/home/cczhong/Desktop/figure.eps", onefile=FALSE, horizontal=FALSE, width=8, height=8)
par(pin=c(6,6))
plot(1 - data[,2], data[,1], type="o", pch=4, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="orange")
par(new=TRUE)
plot(1 - data_ext[,2], data_ext[,1], type="o", pch=4, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="orange")
par(new=TRUE)
plot(1 - data[,5], data[,4], type="o", pch=3, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="red")
par(new=TRUE)
plot(1 - data_ext[,5], data_ext[,4], type="o", pch=3, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="red")
par(new=TRUE)
plot(1 - data[,8], data[,7], type="o", pch=2, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_blue)
par(new=TRUE)
plot(1 - data_ext[,8], data_ext[,7], type="o", pch=2, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_blue)
par(new=TRUE)
plot(1 - data[,11], data[,10], type="o", pch=1, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="darkgreen")
par(new=TRUE)
plot(1 - data_ext[,11], data_ext[,10], type="o", pch=1, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="darkgreen")
par(new=TRUE)
plot(1 - data[,14], data[,13], type="o", pch=5, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_purple)
par(new=TRUE)
plot(1 - data_ext[,14], data_ext[,13], type="o", pch=5, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_purple)
par(new=TRUE)
#plot(1 - data[,6], data[,5], type="o", pch=2, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_blue)
#par(new=TRUE)
#plot(1 - data_ext[,6], data_ext[,5], type="o", pch=2, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_blue)
#par(new=TRUE)
#plot(1 - data[,8], data[,7], type="o", pch=1, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="red")
#par(new=TRUE)
#plot(1 - data_ext[,8], data_ext[,7], type="o", pch=1, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col="red")
#par(new=TRUE)
#plot(1 - data[,10], data[,9], type="o", pch=5, lwd=3, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_purple)
#par(new=TRUE)
#plot(1 - data_ext[,10], data_ext[,9], type="o", pch=5, lwd=3, lty=2, xlim=range(x_l, x_r), ylim=range(y_l, y_r), xlab="1-precision", ylab="recall", col=new_purple)
#par(new=TRUE)
# adding the legend
#legend("bottomright",legend=c("GRASPx", "GRASP+mapping", "FASTM", "PSI-BLAST", "BLASTP"), bg="white", lwd=c(3,3,3,3,3), pch=c(5,1,2,3,4), col=c(new_purple, "red", new_blue, new_yellow, new_vermillion))
#legend("bottomright",legend=c("GRASP(Pfam annotation)", "BLAST(partial)", "BLAST(full)"), lwd=c(3,3,3), pch=c(1,3,4), col=c("red", "green", "blue"))
legend("bottomright",legend=c("GRASP2", "GRASPx", "BLASTP", "PSI-BLAST", "FASTM"), bg="white", lwd=c(3,3,3,3,3), pch=c(4,3,2,1,5), col=c("red", "orange", new_blue, "darkgreen", new_purple))
dev.off()
