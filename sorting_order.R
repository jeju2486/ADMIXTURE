#!/usr/bin/Rscript

# load tidyverse package
library(tidyverse)

Europe <- c("Bergamo","Orcadian","Adygei","Russian","Basque","French","Sardinian","Tuscan")
Africa <- c("BantuN","BantuS","Mandenka","Yoruba","San","Mbuti","Biaka","Mozabite")
E_Asia <- c("Han","Dai","Daur","Hezhen","Lahu","Miao","Oroqen","She","Tujia","Tu","Xibo","Yi","Mongola","Naxi","Cambodian","Japanese","Yakut")
CS_Asia <- c("Balochi","Brahui","Makrani","Sindhi","Pathan","Burusho","Hazara","Uygur","Kalash")
W_Asia <- c("Bedouin","Druze","Palestinian")
Oceania <- c("Melanesian","Papuan")
Americas <- c("Karitiana","Surui","Colombian","Maya","Pima")

# read in data (¡Ønot tibble)
pop <- read.table("/home/projects1/winter2019/swko/HGDP/HGDP.hg19.fam")

#check whether missing population is
tot <- c(Europe,Africa,E_Asia,CS_Asia,W_Asia,Oceania,Americas)
popcheck <- pop[,1]
popcheck <- str_sort(unique(popcheck))
tot <- str_sort(tot)

for(i in 1:length(popcheck)){
  if (length(popcheck)!=length(tot)){
    print("There is some missing population")
    break
    }
  count <- 0
  if (popcheck[i]!=tot[i]){
    print(popcheck[i])
    count <- count+1
    }
  }
if (count==0) print("There is no missing population")
  
#make the vectors in same length
max.len <- max(length(Europe),length(Africa),length(E_Asia),length(CS_Asia),length(W_Asia),length(Oceania),length(Americas))

#make population matrix
geo = list(Europe=Europe,Africa=Africa,E_Asia=E_Asia,CS_Asia=CS_Asia,W_Asia=W_Asia,Oceania=Oceania,Americas=Americas)

attributes(geo) = list(names = names(geo),row.names=1:max.len, class='data.frame')  

# remove nuisance column
poplist <- pop[,1:2]
poplist[,3] <- "NA"

for(i in 1:nrow(poplist)){
  poplist[i,3] <- colnames(geo[grep(toString(paste("\\b",toString(poplist[i,1]),"\\b", sep="")),geo)])
  }
totpop <- unique(as.vector(poplist[order(as.character(poplist[,3])),][,1]))

# Get individual names in the correct order
labels<- poplist[,1:2]

# Name the columns
names(labels)<-c("Pop","ID")

# Add a column with population indices to order
labels$n<-factor(labels$Pop,levels=t(totpop))
levels(labels$n)<-c(1:length(levels(labels$n)))
labels$n<-as.integer(as.character(labels$n))
print(labels$n)

poplist <- poplist[order(labels$n),]
names(poplist) <- c("Pop","ID","geo")

#make output
write.table(poplist,"HGDP.hg19.order.pop",row.names=FALSE,quote=FALSE)
