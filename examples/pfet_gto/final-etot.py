#!/usr/bin/python
import sys
import commands
import time
import os
from scipy import array
import re
import os.path
from scipy.optimize import minimize
import vemb_prime
import integral
import numpy as np

def etot():
    exc=[]
    ii=0
    for line in open('h2.out_44'):
        if " EK_SYS1" in line:
            words=line.split()
            final=len(words)-1
            ek_sys1=float(words[final])
    for line in open('h2-1-1.out'):
        if "!RKS STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys1_ks=words[final]
        if "!MCSCF STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys1=float(words[final])
    for line in open('h2-2-2.out'):
        if "!RKS STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys2=float(words[final])
        if "!RKS expec" in line:
            words=line.split()
            final=len(words)-1
            ek_sys2=float(words[final])
    totfile = open('h4.out_45')
    for line in totfile:
        if "Density functional                   " in line:
            words=line.split()
            exc.append(float(words[2]))
            ii=ii+1
        if " EEXT_SYS2" in line:
            words=line.split()
            final=len(words)-1
            eext_sys2=float(words[final])
        if " EEXT_SYS1" in line:
            words=line.split()
            final=len(words)-1
            eext_sys1=float(words[final])
        if " EEXT_TOT" in line:
            words=line.split()
            final=len(words)-1
            eext_tot=float(words[final])
        if " EJ_SYS2" in line:
            words=line.split()
            final=len(words)-1
            ej_sys2=float(words[final])
        if " EJ_SYS1" in line:
            words=line.split()
            final=len(words)-1
            ej_sys1=float(words[final])
        if " EJ_TOT" in line:
            words=line.split()
            final=len(words)-1
            ej_tot=float(words[final])
        if " EK_TOT" in line:
            words=line.split()
            final=len(words)-1
            ek_tot=float(words[final])
        if " E_EMB" in line:
            words=line.split()
            final=len(words)-1
            e_emb=float(words[final])
        if " E_ION1" in line:
            words=line.split()
            final=len(words)-1
            e_ion1=float(words[final])
        if " E_ION2" in line:
            words=line.split()
            final=len(words)-1
            e_ion2=float(words[final])
    exc_sys1=exc[1]
    exc_sys2=exc[2]
    exc_tot=exc[3]
    ext_int=eext_tot-eext_sys1-eext_sys2
    j_int=ej_tot-ej_sys1-ej_sys2 
    xc_int=exc_tot-exc_sys1-exc_sys2 
    ek_int=ek_tot-ek_sys1-ek_sys2
    e_int=j_int+xc_int+ek_int+e_ion1+e_ion2-e_emb
    myetot=e_sys1+e_sys2+e_int
    print myetot,j_int,xc_int,ek_int,e_ion1,e_ion2,e_emb
    return myetot

#       a=a+1
#   ifile = file( "vemb_real.txt", 'r' )
#   for line in ifile:
#       words = line.split()
#       Vemb_real.append(float(words[0]))
#       b=b+1
#   os.system("../../bin/molpro h2-2-2.com >h2-2-2")
#   os.system("../../bin/molpro h2-1-1.com >h2-1-1")
#   os.system("../../bin/molpro h4.com >h4")
#   fmin(etot,Vemb_real,maxiter=2,disp=1)
   


etot()

