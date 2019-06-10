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

def save_vemb():
   vemb=[]
   totfile = open('vemb.test')
   for line in totfile:
       words=line.split()
       if (len(words)==7):
           for k in range(1,7):
              vemb.append(float(words[k]))
   vemb1=np.zeros(len(vemb))
   for k in range(0,17):
       for i in range(0,6):
           for j in range(0,115):
               vemb1[k*6*115+i*115+j] = vemb[k*6*115+j*6+i] 

   newfile22 = file( 'vemb.test1', 'w' )
   np.savetxt(newfile22,vemb1)
   newfile22.close

save_vemb()

