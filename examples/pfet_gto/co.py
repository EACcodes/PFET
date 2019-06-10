#!/usr/bin/python
import sys
import commands
import os
from scipy import array

itot = 0 
ifile = file( "vemb_real.txt", 'r' )
myVS = []
nucpot = []
myden = []
myden2 = []
myI1 = []
myI2 = []
myX = []
myY = []
myZ = []
a = 0
for line in ifile:
    words = line.split()
    myden.append(float(words[0]))
#    nucpot.append(float(words[2]))
    a=a+1
kfile = file( "file3.txt", 'r' )
for line in kfile:
    words = line.split()
    myX.append(float(words[1]))
    myY.append(float(words[2]))
    myZ.append(float(words[3]))
newfile = file( "newfile-h4.txt", 'w' )
for i in range(0,a):
    if (abs(myZ[i]-11.338355931)<1e-6 and abs(myX[i]-11.338355931)<1e-6):
        print >> newfile, '%10.6f'%myY[i],'%16.8f'%myden[i]
newfile.close()
 
