#!/bin/bash
# run_admixture_sh

pt1=($(pwd)"/")
FILE_O="/home/projects1/winter2019/swko/HGDP/HGDP.hg19"
FILE="/home/projects1/winter2019/swko/ADMIXTURE/HGDP.hg19"
of1="HGDP.hg19"
tn1="temp1_"${of1}

cd /home/projects1/winter2019/swko/ADMIXTURE/

mkdir -p ./ADMIXTURE_result/; cd ./ADMIXTURE_result/

## Extract individuals
plink --bfile ${FILE_O} --geno 0.01 --allow-no-sex --make-bed --out ${tn1}_2

## Then, remove rare alleles (maf < 1%) and prune by LD (n=118,387)
plink --bfile ${tn1}_2 --maf 0.01 --allow-no-sex --make-bed --out ${tn1}_3
plink --bfile ${tn1}_3 --indep-pairwise 200 25 0.2 --out ${tn1}_4
plink --bfile ${tn1}_3 --extract ${tn1}_4.prune.in --make-bed --out ${tn1}_4

for K in bed bim fam; do cp ${tn1}_4.${K} ${of1}.${K}; done
awk '{print $1,$2}' ${of1}.fam > ${of1}.header

rm ${tn1}_*

#run ADMIXTURE
cd /home/projects1/winter2019/swko/ADMIXTURE/ADMIXTURE_result/

runf="admrun"
tpf="ADMrun_template.sh"
nreps=5
Kmax=7
nchunks=25

for K in $(seq 1 $nchunks); do echo -e '#!/bin/bash\n' > ${runf}.${K}.sh; chmod 755 ${runf}.${K}.sh; done

## Now, jobs are split into chunks in an evener way
cnum=1; dval=1
for K in $(seq 3 $Kmax); do for nrep in $(seq 1 $nreps); do
    tail -n +3 ${tpf} | sed s/"KVAL"/${K}/g | sed s/"NREP"/${nrep}/g >> ${runf}.${cnum}.sh
    let cnum+=${dval}
    if [ "$cnum" -gt "$nchunks" ] || [ "$cnum" -lt 1 ]; then
        let dval=-1*${dval}; let cnum+=${dval}
    fi
done; done

for K in $(seq 1 $nchunks); do sbatch -c 8 --mem 32000 ${runf}.${K}.sh; done

# Retrieve CV error and LL info and get the merged Q matrix  

fn1="HGDP.hg19"
py="/home/projects1/winter2019/swko/ADMIXTURE/HGDP.hg19_wrapup.py"

## Tabulate LL and CVerror
for nrep in $(seq 1 $nreps); do
    CV=""; LL=""
    for K in $(seq 3 $Kmax); do
        tfn1=${fn1}"_K"${K}"_"${nrep}".log"
        tCV=($(grep "CV error" ${tfn1} | cut -d ' ' -f 4))
        tLL=($(grep "Loglikelihood" ${tfn1} | tail -1 | cut -d ' ' -f 2))
        if [ "$K" -eq 2 ]; then CV+=${tCV}; LL+=${tLL}; else CV+=" "${tCV}; LL+=" "${tLL}; fi
    done
    echo ${CV} >> ${fn1}_CVerror
    echo ${LL} >> ${fn1}_LL
done