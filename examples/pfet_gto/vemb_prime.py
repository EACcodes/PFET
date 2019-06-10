#!/usr/bin/python
import sys
import commands
import time
import os
from scipy import array
import re
import os.path
from scipy.optimize import fmin
import numpy as np

def vemb_p(Vemb):
   fun_der2=[]
   fun_der1=[]
   Vemb1 = []
   Vemb2 = []
   Vemb11 = []
   Vemb22 = []
   voep_sys1=[]
   v_ion1=[]
   v_ion2=[]
   totfile = open('h2o-dimer.out')
   for line in totfile:
      if "MATRIX FUN_DER2" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 fun_der2.append(float(words[j]))
             if (len(words)==0):
              break;
      if "MATRIX FUN_DER1" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 fun_der1.append(float(words[j]))
             if (len(words)==0):
                 break;
   totfile = open('sys2.out')
   for line in totfile:
      if "MATRIX TEST" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 v_ion2.append(float(words[j]))
             if (len(words)==0):
                  break;
   totfile = open('sys1-oep.out')
   for line in totfile:
      if "MATRIX VS_FINAL" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 voep_sys1.append(float(words[j]))
             if (len(words)==0):
                  break;
      if "MATRIX TEST" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 v_ion1.append(float(words[j]))
             if (len(words)==0):
                  break;
   for i in range(0,len(fun_der2)):
       Vemb1.append(Vemb[i]+0.01*(fun_der1[i]+voep_sys1[i]))
       Vemb2.append(Vemb[i]+0.01*(fun_der2[i]))
       Vemb11.append(Vemb[i]-0.01*(fun_der1[i]+voep_sys1[i]))
       Vemb22.append(Vemb[i]-0.01*(fun_der2[i]))
   newfile22 = file( 'vemb22.molpro', 'w' )
   np.savetxt(newfile22,Vemb22)
   newfile22.close
   newfile11 = file( 'vemb11.molpro', 'w' )
   np.savetxt(newfile11,Vemb11)
   newfile11.close
   newfile2 = file( 'vemb2.molpro', 'w' )
   np.savetxt(newfile2,Vemb2)
   newfile2.close
   newfile1 = file( 'vemb1.molpro', 'w' )
   np.savetxt(newfile1,Vemb1)
   newfile1.close

