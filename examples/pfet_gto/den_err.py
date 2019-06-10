#!/usr/bin/python
import sys
import commands
import os
from scipy import array

itot = 0 
ifile = file( "file2.txt", 'r' )
myI = []
myJ = []
myK = []
a = 0
for line in ifile:
    words = line.split()
    myI.append(float(words[0]))
jfile = file( "file1.txt", 'r' )
for line in jfile:
    words = line.split()
    myJ.append(float(words[0]))
kfile = file( "file3.txt", 'r' )
for line in kfile:
    words = line.split()
    myK.append(float(words[4]))
mynumber = 0.0
for itot in range(0,len(myJ)):
    mynumber += abs(myJ[itot]-myI[itot])*myK[itot]
print '%lf'%mynumber
        
