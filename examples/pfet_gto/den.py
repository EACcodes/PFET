#!/usr/bin/python
import sys
import commands
import os
from scipy import array
import numpy as np

itot = 0 
ifile = file( "sys1-0", 'r' )
myVS = []
nucpot = []
myden1 = []
myden2 = []
myden = []
myI1 = []
myI2 = []
myX = []
myY = []
myZ = []
a = 0
for line in ifile:
    words = line.split()
    myden1.append(float(words[0]))
#    nucpot.append(float(words[2]))
    a=a+1
myden_sum = np.zeros(a)
jfile = file('sys2-0','r')
for line in jfile:
    words = line.split()
    myden2.append(float(words[0]))

jfile = file('test','r')
for line in jfile:
    words = line.split()
    myden.append(float(words[0]))
kfile = file( "file3.txt", 'r' )
for line in kfile:
    words = line.split()
    myX.append(float(words[1]))
    myY.append(float(words[2]))
    myZ.append(float(words[3]))
newfile = file( "newfile-h4.txt", 'w' )
for i in range(0,a):
    myden_sum[i]=myden1[i]+myden2[i]-myden[i]
    if (abs(myZ[i]-11.338355931)<1e-6 and abs(myX[i]-11.338355931)<1e-6):
        print >> newfile, '%10.6f'%myY[i],'%16.8f'%myden_sum[i]
newfile.close()
 
