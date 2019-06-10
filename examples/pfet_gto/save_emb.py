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

def save_emb():
   myden1=[]
   vj1=[]
   vex1=[]
   voep_sys1=[]
   totfile = open('test.out')
   for line in totfile:
      if "MATRIX EMB_INT      " in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                vex1.append(float(words[j]))
             if (len(words)==0):
              break;
 
   newfile22 = file( 'vemb.molpro', 'w' )
   np.savetxt(newfile22,vex1)
   newfile22.close
save_emb()
