#!/usr/bin/python
import sys
import commands
import os
from scipy import array
import re
import os.path
import numpy as np

vemb_real=[]
#newfile = file( 'vemb.molpro', 'w' )
a=115*115
#myVemb=np.zeros(a)
#np.savetxt(newfile,myVemb)
#newfile.close()
#os.system("cp vemb.molpro vemb1.molpro")
#os.system("cp vemb.molpro vemb2.molpro")
#os.system("cp vemb.molpro vemb11.molpro")
#os.system("cp vemb.molpro vemb22.molpro")
vemb_f=np.full((a,1),1)
vemb_f[0]=0.0
newfile = file( 'vemb_f.molpro', 'w' )
np.savetxt(newfile,vemb_f)
newfile.close()

vemb_real=np.zeros(128916)
newfile = file( 'vemb_real.txt', 'w' )
np.savetxt(newfile,vemb_real)
newfile.close()

