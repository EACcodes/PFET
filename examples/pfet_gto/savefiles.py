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

def save_test():
   myden1=[]
   vj1=[]
   vxc=[]
   vex1=[]
   totfile = open('test.out')
   for line in totfile:
      if "MATRIX EMB_INT       " in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                vxc.append(float(words[j]))
             if (len(words)==0):
              break;
   newfile22 = file( 'vemb.molpro', 'w' )
   np.savetxt(newfile22,vxc)
   newfile22.close

def save_foep():
   myden1=[]
   vj1=[]
   vxc=[]
   vex1=[]
   totfile = open('sys1-oep.out')
   for line in totfile:
      if "MATRIX VXC" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                vxc.append(float(words[j]))
             if (len(words)==0):
              break;
   newfile22 = file( 'vxc_sys1.molpro', 'w' )
   np.savetxt(newfile22,vxc)
   newfile22.close

def save_f1():
   myden1=[]
   vj1=[]
   vxc=[]
   vex1=[]
   totfile = open('sys1.out')
   for line in totfile:
      if "MATRIX TEST1" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                vex1.append(float(words[j]))
             if (len(words)==0):
              break;
      if "MATRIX J" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 vj1.append(float(words[j]))
             if (len(words)==0):
                 break;
      if "MATRIX D" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 myden1.append(float(words[j]))
             if (len(words)==0):
              break;

   newfile22 = file( 'myden1.molpro', 'w' )
   np.savetxt(newfile22,myden1)
   newfile22.close

   newfile22 = file( 'vj1.molpro', 'w' )
   np.savetxt(newfile22,vj1)
   newfile22.close

   newfile22 = file( 'vex1.molpro', 'w' )
   np.savetxt(newfile22,vex1)
   newfile22.close
def save_f2():
   myden1=[]
   vj1=[]
   vex1=[]
   totfile = open('sys2.out')
   for line in totfile:
      if "MATRIX EPOT" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                vex1.append(float(words[j]))
             if (len(words)==0):
              break;
      if "MATRIX D" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 myden1.append(float(words[j]))
             if (len(words)==0):
              break;
      if "MATRIX J" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 vj1.append(float(words[j]))
             if (len(words)==0):
                 break;
 
   newfile22 = file( 'myden2.molpro', 'w' )
   np.savetxt(newfile22,myden1)
   newfile22.close

   newfile22 = file( 'vj2.molpro', 'w' )
   np.savetxt(newfile22,vj1)
   newfile22.close

   newfile22 = file( 'vex2.molpro', 'w' )
   np.savetxt(newfile22,vex1)
   newfile22.close
      

def save_f11():
   myden1=[]
   myden11=[]
   vj1=[]
   vex1=[]
   totfile = open('sys1-0.out')
   for line in totfile:
      if "MATRIX D" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 myden1.append(float(words[j]))
             if (len(words)==0):
              break;
   totfile.closed
   totfile = open('sys1-00.out')
   for line in totfile:
      if "MATRIX D" in line:
         for i in range(0,2): 
             line=next(totfile)
         for k in range(0,2000):
             line=next(totfile)
             words=line.split()
             for j in range(0,len(words)):
                 myden11.append(float(words[j]))
             if (len(words)==0):
              break;
 
   newfile22 = file( 'myden1-1.molpro', 'w' )
   np.savetxt(newfile22,myden1)
   newfile22.close

   newfile22 = file( 'myden1-11.molpro', 'w' )
   np.savetxt(newfile22,myden11)
   newfile22.close
