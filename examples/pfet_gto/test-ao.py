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
import savefiles

def etot(Vemb):
    newfile = file( 'vemb.molpro', 'w' )
    np.savetxt(newfile,Vemb)
    newfile.close()
    exc=[]
    exc1=[]
    iii=0
    ii=0
    fun_der1=[]
    fun_der2=[]
    myden1=[]
    myden2=[]
    myden1_new=[]
    myden2_new=[]
#subsystem 1 embedding calculation
    os.system("molpro sys1.com")
    savefiles.save_f1()
#subsystem 1 inv_KS
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys1-oep.com >sys1-oep")
#subsystem 2 embdedding calculation
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys2.com >sys2")
    savefiles.save_f2()
    savefiles.save_foep()
#total system inv_KS
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 h2o-dimer.com >h2o-dimer")
#get the shiftted embedding potentials
    vemb_prime.vemb_p(Vemb)
#embedding calculation for subsystems with shifted embedding potentials
    os.system("molpro sys1-0.com")
    os.system("molpro sys1-00.com")
    savefiles.save_f11()
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys1-1.com >sys1-1")
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys2-2.com >sys2-2")
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys1-11.com >sys1-11")
    os.system("/scratch/gpfs/qou/Molpro_test/Molpro/bin/molpro -n 2 sys2-22.com >sys2-22")
#calculate the gradient and total energy
    for line in open('sys1-11'):
       words = line.split()
       myden1.append(float(words[0]))
    for line in open('sys2-22'):
       words = line.split()
       myden2.append(float(words[0]))
    for line in open('sys1-1'):
       words = line.split()
       myden1_new.append(float(words[0]))
    for line in open('sys2-2'):
       words = line.split()
       myden2_new.append(float(words[0]))
    mygrad_real=np.zeros(len(myden1))
    for i in range(0,len(myden1)):
        mygrad_real[i]=50*(myden1_new[i]+myden2_new[i]-myden1[i]-myden2[i])
    mygrad=integral.myintegral_grad(mygrad_real,len(mygrad_real))
    for line in open('sys1-oep.out'):
        if " EK_SYS1" in line:
            words=line.split()
            final=len(words)-1
            ek_sys1=float(words[final])
        if "Density functional               " in line:
            words=line.split()
            exc1.append(float(words[2]))
            iii=iii+1
    for line in open('sys1.out'):
        if "!MCSCF STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys1=float(words[final])
    for line in open('sys2.out'):
        if "!RKS STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys2=float(words[final])
        if "!RKS expec" in line:
            words=line.split()
            final=len(words)-1
            ek_sys2=float(words[final])
        if "Density functional                   " in line:
            words=line.split()
            exc_sys2=float(words[2])
    totfile = open('h2o-dimer.out')
    for line in totfile:
        if "Density functional                   " in line:
            words=line.split()
            exc.append(float(words[2]))
            ii=ii+1
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
        if " E_IONTOT" in line:
            words=line.split()
            final=len(words)-1
            e_ion=float(words[final])
        if " E_ION1" in line:
            words=line.split()
            final=len(words)-1
            e_ion1=float(words[final])
        if " E_ION2" in line:
            words=line.split()
            final=len(words)-1
            e_ion2=float(words[final])
    exc_sys1=exc1[1]
    exc_tot=exc[1]
    j_int=ej_tot-ej_sys1-ej_sys2 
    xc_int=exc_tot-exc_sys1-exc_sys2 
    ek_int=ek_tot-ek_sys1-ek_sys2
    e_int=j_int+xc_int+ek_int+e_ion1+e_ion2-e_emb 
    myetot=e_sys1+e_sys2+e_int
    myresult=file('pfet.out','a')
    print >>myresult, ek_tot,ek_sys1,myetot,j_int,xc_int,ek_int,e_ion1,e_ion2,e_emb
    return (myetot,mygrad)

def setup():
   newfile=file('vemb.molpro','r')
   Vemb = np.loadtxt(newfile)

   result = minimize(etot,Vemb,method='BFGS', jac=True,tol=1e-6,options={'disp': True})
#   etot(Vemb)

def grad_vemb(Vemb_real,myden1,myden2,myden1_new,myden2_new,b):
   grad=[]
   for i in range(0,b):
       grad.append(10000*(myden1_new[i]+myden2_new[i]-myden1[i]-myden2[i]))
   return grad


setup()

