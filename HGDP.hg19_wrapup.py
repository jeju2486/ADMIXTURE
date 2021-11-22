#! /usr/bin/env python
import re, os, gzip
from operator import itemgetter
import numpy as np

def column(mat, i):
    return [row[i] for row in mat]

inFile = "HGDP.hg19"
maxK = 7
nreps = 5

outFile = inFile + "_topruns.Q"

## Define a focal population to decide order in K=2 case
tpop = 'Biaka'

r1 = os.getcwd() + "\ADMIXTURE_result/"; os.chdir(r1)
print(os.getcwd())

Kvals = [str(val) for val in range(3, int(maxK)+1)]; nreps = int(nreps)

## Import Loglikelihood information; assess convergence; return the top run
temp_LLs = [line.strip().split() for line in open(inFile + "_LL", "r").readlines()]
LLs = [[float(val) for val in column(temp_LLs, i)] for i in range(len(temp_LLs[0]))]

tnums = []
for k,LL in enumerate(LLs):
    t1s = [[i+1,val] for i,val in enumerate(LL)]
    t1s = sorted(t1s, key=itemgetter(1), reverse=True)
    tnums.append(str(t1s[0][0]))
    if nreps >= 5:
        tdiff1 = t1s[0][1] - t1s[4][1]
        string = "K = " + str(k+2) + "\t1st - 5th = " + str(tdiff1)
    if nreps >= 10:
        tdiff2 = t1s[0][1] - t1s[9][1]
        string += "\t1st - 10th = " + str(tdiff2)
    if nreps >= 5:
        print(string)


## Import top run Q matrices
Qs = []
for i,Kval in enumerate(Kvals):
    tpname = inFile + "_K" + Kval + "_" + tnums[i] + ".Q.gz"
    t1s = [line.strip().split()[2:] for line in gzip.open(tpname, "rb").readlines()]
    Qs.append([[float(val) for val in column(t1s,j)] for j in range(len(t1s[0]))])
    if i == 0:
        headers = [line.decode('UTF-8').strip().split()[0:2] for line in gzip.open(tpname, "rb").readlines()]

## Define order in K = 2 case
if "fpop" in locals():
    tmns = [[np.mean([v for i,v in enumerate(vs) if headers[i][0] == fpop]),j] for j,vs in enumerate(Qs[0])]
    torders = [v[1] for v in sorted(tmns, key=itemgetter(0))]
    Q2s = []; Q2s.append([[val for val in Qs[0][i]] for i in torders])


if "fpop" not in locals():
    Q2s = []; Q2s.append([[val for val in qvec] for qvec in Qs[0]])



## Re-order columns by finding similar columns in previous K value
for i in range(1, len(Qs)):
    onums = []
    for q1 in Q2s[i-1]:
        v1 = np.array([val for val in q1])
        t1s = [[j,sum(abs(v1 - np.array([val for val in q2])))] for j,q2 in enumerate(Qs[i])]
        t2s = [val[0] for val in sorted(t1s, key=itemgetter(1))]
        tmax = [t2 for t2 in t2s if t2 not in onums][0]
        onums.append(tmax)
    onums.extend(list(set(range(i+2))-set(onums)))
    Q2s.append([[val for val in Qs[i][j]] for j in onums])


## Export output in a big concatenated table
d1s = [column(headers,0), column(headers,1)]
hvec = ["Pop", "ID"]
for i,Q2 in enumerate(Q2s):
    hvec.extend(["K" + str(i+3) + ":" + str(val) for val in range(1,i+4)])
    for qvec in Q2:
        d1s.append(["{0:.5f}".format(qval, 5) for qval in qvec])

F1 = open(outFile, "w")
F1.writelines(' '.join(hvec) + "\n")

for i in range(len(headers)):
    F1.writelines(' '.join(column(d1s,i)) + "\n")

F1.close()

path = r1+outFile
with open(path,'rb') as f_in:
    with gzip.open(path+'.gz','wb') as f_out:
        f_out.writelines(f_in)



