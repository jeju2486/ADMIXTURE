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

#check whether missing population is

tot <- c(Europe,Africa,E_Asia,CS_Asia,W_Asia,Oceania,Americas)

pop <- read.table("../PCA/HGDP.hg19.ind")
pop <- pop[,3]
pop <- str_sort(unique(pop))
tot <- str_sort(tot)

for(i in 1:length(pop)){
  if (length(pop)!=length(tot)){
    break
    }
  count <- 0
  if (pop[i]!=tot[i]){
    print(pop[i])
    count <- count+1
    }
  }
if (count==0) print("It is OK")
  
#make the vectors in same length

max.len <- max(length(Europe),length(Africa),length(E_Asia),length(CS_Asia),length(W_Asia),length(Oceania),length(Americas))

#make population matrix

geo = list(Europe=Europe,Africa=Africa,E_Asia=E_Asia,CS_Asia=CS_Asia,W_Asia=W_Asia,Oceania=Oceania,Americas=Americas)

attributes(geo) = list(names = names(geo),row.names=1:max.len, class='data.frame')  

# read in data (¡Øtibble)
poplist <- read_table2("../PCA/HGDP.hg19.ind", col_names = FALSE)

# remove nuisance column
poplist <- poplist[,-c(2)]
poplist[,3] <- "NA"


for(i in 1:nrow(poplist)){
  poplist[i,3] <- colnames(geo[grep(toString(paste("\\b",toString(poplist[i,2]),"\\b", sep="")),geo)])
  }

#make output
write.table(indpop,"HGDP.hg19.pop",col.names=FALSE,row.names=FALSE,quote=FALSE)
