#!/usr/bin/python
import sys
import commands
import time
import os
from scipy import array
import re
import os.path
from scipy.optimize import fmin
import vemb_prime
import numpy as np

def myintegral_grad(mygrad_real,a):
   myao = []
   mywts = []
   nucpot = []
   myden = []
   myden2 = []
   myI1 = []
   myI2 = []
   myX = []
   myY = []
   myZ = []
   jfile = file( "ao_basis", 'r' )
   myao=np.loadtxt(jfile)
   mygrad=np.zeros(115*115)
   kfile = file( "file3.txt", 'r' )
   for line in kfile:
       words = line.split()
       mywts.append(float(words[4]))
   ngrid=len(mywts)
   nbas=a
   v_w = np.multiply(mywts,mygrad_real)
   buf = np.ndarray((nbas,ngrid),dtype=float)
   phi = myao.reshape((nbas,ngrid))
   for i in range(nbas):
       phi_v_w(phi[i,:],v_w,buf[i,:])

   mygrad = np.dot(phi,buf.T)
   mygrad = mygrad.reshape((nbas*nbas))
   return mygrad


def phi_v_w(phi,v_w, buf):

    np.multiply(phi, v_w, out=buf)



