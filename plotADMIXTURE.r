## I conducted 5 runs for each K value
rm(list=ls())
gname = "HGDP.hg19"
rdwd = "D:\\R\\ADMIXTURE\\ADMIXTURE_result\\"
setwd("D:\\R\\ADMIXTURE")

## CV error distribution for the top K replicates
CVs = read.table(paste(rdwd,gname, "_CVerror", sep=""), header=F)

## box plot for CV errors of all replicates
png(paste(gname, "_CVerror_all.png", sep=""), height=20, width=1.5*ncol(CVs), res=300, units="cm")
par(cex.main=1.2, cex.axis=1, cex.lab=1)
par(mar=c(5.1,4.6,4.1,2.1))
boxplot(CVs, xlab="K", ylab="CV error", xaxt="n", main="")
mtext(3, text=gname, line=2.2, cex=1.3, font=2)
mtext(3, text="CV error for all replicates", line=0.8, cex=1.2)
axis(side=1, at=1:ncol(CVs), label=(1:ncol(CVs))+2)
dev.off()


## Generate random colors for each component
cvals.all = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]
set.seed(332); cvals = sample(cvals.all, 50, replace=F)
cvals[3] = "darkgoldenrod2"

## Generate admixture plot for the top 1 replicates

## Import top run output
d1 = read.table(gzfile(paste(gname, "topruns.Q.gz", sep="_")), header=T)

tpids = as.vector(d1$Pop)
tiids = as.vector(d1$ID)

pdata = data.frame(tpids, tiids); names(pdata) = names(d1)[1:2]
d1 = d1[, 3:ncol(d1)]; tpopvec = as.vector(as.matrix(pdata[,1]))

## Import ordered population IDs and keep those present in the data
## Also, import the plotting group labels
popinfo = read.table(paste(gname, "popinfo", sep="."), header=F)
names(popinfo) = c("Pop","geo")
popinfo.fv = c()
for (i in 1:nrow(popinfo)) {
  popinfo.fv = c(popinfo.fv, as.vector(as.matrix(popinfo[i,1])) %in% tpopvec)
}
popinfo = popinfo[popinfo.fv, ]
pnames = as.vector(as.matrix(popinfo[,1]))
grnames = as.vector(popinfo$geo)

## Assign color to each language family
LFs = as.vector(popinfo$geo); LFs[is.na(LFs)] = "Others"
LFnames = as.vector(unique(LFs))

set.seed(332)
rgbcolvec = matrix(sample(0:255, length(LFnames)*3, replace=T), ncol=3, byrow=T)
LFcols = rgb(rgbcolvec[,1], rgbcolvec[,2], rgbcolvec[,3], maxColorValue=255)


## First, reorder data by the given order or populations
## and generate per-individual plotting group name vector
ords = c(); lg.cv = c(); grnv = c()
for (i in 1:length(pnames)) {
  tlg.col = LFcols[LFnames == LFs[i]]
  grnv = c(grnv, rep(grnames[i], sum(tpopvec == pnames[i])))
  lg.cv = c(lg.cv, rep(tlg.col, sum(tpopvec == pnames[i])))
  ords = c(ords, which(tpopvec == pnames[i]))
}

blank.nums = c(); t.gr = grnv[1]
for (i in 2:length(grnv)) {
  if (grnv[i] != t.gr) {
    blank.nums = c(blank.nums, i + length(blank.nums))
    t.gr = grnv[i]
  }
}

lg.cv2 = rep("white", length(lg.cv)+length(blank.nums))
lg.cv2[-1*blank.nums] = lg.cv
lg.cv = lg.cv2

Kmax = round(sqrt(2*ncol(d1) + 2.25) - 0.5)
empty.cnums = c()
for (i in 3:Kmax) { empty.cnums = c(empty.cnums, sum(3:i)+(i-2)) }

d2 = matrix(0, nrow=length(lg.cv), ncol=ncol(d1)+Kmax-2)
popvec = rep("", length(lg.cv))
idvec = rep("", length(lg.cv))
d2[-1*blank.nums, -1*empty.cnums] = as.matrix(d1)[ords, ]
d2[blank.nums, empty.cnums] = 1
popvec[-1*blank.nums] = as.vector(as.matrix(pdata[,1]))[ords]
idvec[-1*blank.nums] = as.vector(as.matrix(pdata[,2]))[ords]

## Assign color to each component
cvec = c(); for (k in 3:Kmax) cvec = c(cvec, c(cvals[1:k],"white"))


npr = 1100   ## # of samples per line
dist = 2.5  ## distance between rows
nrs = ceiling(nrow(d2) / npr)

##labeling control
cpopvec = c(rep("",length(popvec)))
cpopvec[1]=popvec[1]
for (i in 2:length(popvec)){
  if (popvec[i]==popvec[i-1]){
    cpopvec[i]=""
  }
  else{cpopvec[i] = popvec[i]}
}


## Plot for each figure; add an empty line between each population
pdf.name = paste(gname, "_perK_top.pdf", sep="")
pdf(pdf.name, height=dist*nrs, width=npr/80, colormodel="cmyk")
par(mar=c(0.1,0.1,0.1,0.1))

for (K in 3:Kmax) {
  tcnums = (sum(3:K)-2):sum(4:(K+1))
  td2 = d2[, tcnums]
  txv = rep(1:nrow(td2), K+1)
  tyv0 = rep(0, nrow(td2))
  tyv1 = as.vector(as.matrix(td2[,1]))
  for (J in 2:ncol(td2)) {
    if (J == 2) { tyv0 = c(tyv0, tyv1) }
    else { tyv0 = c(tyv0, as.vector(apply(td2[,1:(J-1)], 1, sum))) }
    tyv1 = c(tyv1, as.vector(apply(td2[,1:J], 1, sum)))
  }
  cv = rep(c(cvals[1:K], "white"), each=nrow(td2))
  
  xv = txv %% npr; xv[xv == 0] = npr
  xrnums = nrs - floor((txv - 1) / npr)  ## in which row each value would be
  yv0 = tyv0 + dist*xrnums + xrnums - 1
  yv1 = tyv1 + dist*xrnums + xrnums - 1
  
  ## lgv = paste(popvec, idvec, sep=":"); lgv[lgv == ":"] = ""
  lgv = paste(popvec, substring(idvec,5), sep=":")
  lgxv = xv[1:nrow(td2)]-0.5
  lgyv = yv0[1:nrow(td2)]
  
  plot(c(0, npr/2), c(0, (dist+1)*nrs+1), type="n", xaxt="n", yaxt="n", xlab="", ylab="", bty="n")
  rect(xleft=(xv-1)*0.5, xright=xv*0.5, ybottom=yv0, ytop=yv1, border=NA, col=cv)
  ##text(x=lgxv, y=lgyv-0.1, label=lgv, srt=90, cex=0.5, adj=c(1,0.5), font=2, col=lg.cv)
  text(x=lgxv*0.5, y=lgyv+1.1, label=cpopvec, srt=90, cex=0.5, adj=c(0,0.5), font=2, col=lg.cv2)
}
dev.off()



## Plot all K's in one figure; cut into chunks
dist2 = 0.1; npr2 = 300; nchunks = ceiling(nrow(d2) / npr2)
td2 = d2; td2[, empty.cnums] = d2[, empty.cnums] + dist2
txv = rep(1:nrow(td2), ncol(td2))
tyv0 = rep(0, nrow(td2))
tyv1 = as.vector(as.matrix(td2[,1]))
for (J in 2:ncol(td2)) {
  if (J == 2) { tyv0 = c(tyv0, tyv1) }
  else { tyv0 = c(tyv0, as.vector(apply(td2[,1:(J-1)], 1, sum))) }
  tyv1 = c(tyv1, as.vector(apply(td2[,1:J], 1, sum)))
}
tcv = rep(cvec, each=nrow(td2))
ymin = 0; ymax = (dist2+1)*(Kmax-2)-dist2

pdf.name = paste(gname, "_allK_top.pdf", sep="")
pdf(pdf.name, height=1.0*(Kmax-2), width=npr2/8, colormodel="cmyk")
par(mar=c(0.1,0.1,0.1,0.1))

for (i in 1:nchunks) {
  tx0 = npr2 * (i-1)+1; tx1 = npr2*i
  tfv1 = (txv >= tx0 & txv <= tx1)
  xv = txv[tfv1] - npr2*(i-1)
  yv0 = tyv0[tfv1]; yv1 = tyv1[tfv1]
  cv = tcv[tfv1]
  
  tlg.fv1 = (1:length(popvec)) >= tx0 & (1:length(popvec)) <= tx1
  lgv = popvec[tlg.fv1]
  lgxv = (1:length(lgv))-0.5
  lg.cv2 = lg.cv[tlg.fv1]
  
  plot(c(0, npr2), c(ymin-1.2, ymax+1.2), type="n", xaxt="n", yaxt="n", xlab="", ylab="", bty="n")
  rect(xleft=xv-1, xright=xv, ybottom=yv0, ytop=yv1, border=NA, col=cv)
  text(x=lgxv, y=ymin-0.1, label=lgv, srt=90, cex=0.7, adj=c(1,0.5), font=2, col=lg.cv2)
  text(x=lgxv, y=ymax+0.1, label=lgv, srt=90, cex=0.7, adj=c(0,0.5), font=2, col=lg.cv2)
}
dev.off()