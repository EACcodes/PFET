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

def etot(Vemb_real):
    Vemb=integral.myintegral(Vemb_real,len(Vemb_real))
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
    os.system("../../../bin/molpro sys1.com >sys1")
    savefiles.save_f1()
    os.system("../../../bin/molpro sys2.com >sys2")
    savefiles.save_f2()
    os.system("../../../bin/molpro h2o-dimer.com >h2o-dimer")
    vemb_prime.vemb_p(Vemb)
    os.system("../../../bin/molpro sys1-1.com >sys1-1")
    os.system("../../../bin/molpro sys2-2.com >sys2-2")

    for line in open('sys1'):
       words = line.split()
       myden1.append(float(words[0]))
    for line in open('sys2'):
       words = line.split()
       myden2.append(float(words[0]))
    for line in open('sys1-1'):
       words = line.split()
       myden1_new.append(float(words[0]))
    for line in open('sys2-2'):
       words = line.split()
       myden2_new.append(float(words[0]))
    mygrad=np.zeros(len(myden1))
    for i in range(0,len(myden1)):
        mygrad[i]=200*(myden1_new[i]-myden1[i])+40*(myden2_new[i]-myden2[i])
    for line in open('sys1.out'):
        if " EK_SYS1" in line:
            words=line.split()
            final=len(words)-1
            ek_sys1=float(words[final])
        if "!RKS STATE 1.1 Energy" in line:
            words=line.split()
            final=len(words)-1
            e_sys1=float(words[final])
        if "Density functional                   " in line:
            words=line.split()
            exc1.append(float(words[2]))
            iii=iii+1
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
   Vemb_real = np.zeros(27115)
   a = 115*115
   b = 27115
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
   result = minimize(etot,Vemb_real,method='L-BFGS-B', jac=True,options={'disp': True,'ftol':1e-6})
#   etot(Vemb_real)
   newfile = file( 'vemb_real_final.txt', 'w' )
   np.savetxt(newfile,Vemb_real)
   newfile.close()
   

def grad_vemb(Vemb_real,myden1,myden2,myden1_new,myden2_new,b):
   grad=[]
   for i in range(0,b):
       grad.append(10000*(myden1_new[i]+myden2_new[i]-myden1[i]-myden2[i]))
   return grad


setup()

