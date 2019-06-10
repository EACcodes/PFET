memory,2000,m
symmetry,NOSYM

 geometry={
Al1            8.0929600000E+00  4.0464800000E+00 -2.3500188843E-15
Al2            8.0929600000E+00  6.0697200000E+00 -2.0232400000E+00
Al3            1.0116200000E+01  4.0464800000E+00 -2.0232400000E+00
Al4            6.0697200000E+00  4.0464800000E+00 -2.0232400000E+00
Al5            8.0929600000E+00  2.0232400000E+00 -2.0232400000E+00
Al6            8.0929600000E+00  4.0464800000E+00 -4.0464800000E+00
Al7            6.0697200000E+00  6.0697200000E+00 -3.2900264381E-15
Al8            1.0116200000E+01  2.0232400000E+00 -9.4000755373E-16
Al9            1.0116200000E+01  6.0697200000E+00 -4.0464800000E+00
Al10           6.0697200000E+00  2.0232400000E+00 -1.8800151075E-15
Al11           6.0697200000E+00  6.0697200000E+00 -4.0464800000E+00
Al12           1.0116200000E+01  2.0232400000E+00 -4.0464800000E+00
 C1  9.46019384628 5.41371384628 -0.65600615372
 O1  10.114909231 6.06842923101 -0.00129076898569
 }
 dummy,Al1,Al2,Al3,Al4,Al5,Al6,C1,O1
 
basis={
!
! CARBON       (4s,4p) -> [2s,2p]
! CARBON       (4s,4p)->[2s,2p]
s, C , 2.2631010, 1.7731860, 0.4086190, 0.1391750
c, 1.3, 0.4965480, -0.4223910, -0.5993560
c, 4.4, 1
p, C , 8.3830250, 1.9931320, 0.5595430, 0.1561260
c, 1.3, -0.0385440, -0.2031850, -0.4981760
c, 4.4, 1
! OXYGEN       (4s,5p) -> [2s,3p]
! OXYGEN       (4s,5p)->[2s,3p]
s, O , 47.1055180, 5.9113460, 0.9764830, 0.2960700
c, 1.3, -0.0144080, 0.1295680, -0.5631180
c, 4.4, 1
p, O , 16.6922190, 3.9007020, 1.0782530, 0.2841890, 0.0702000
c, 1.3, 0.0448560, 0.2226130, 0.5001880
c, 4.4, 1
c, 5.5, 1
! ALUMINUM       (4s,4p) -> [2s,2p]
! ALUMINUM       (4s,4p)->[2s,2p]
s, AL , 2.7863370, 1.1436350, 0.1700270, 0.0673240
c, 1.3, -0.0464110, 0.2744720, -0.6252340
c, 4.4, 1
p, AL , 0.9837940, 0.3582450, 0.1381580, 0.0449750
c, 1.3, 0.0520360, -0.1550940, -0.5325840
c, 4.4, 1
! ELEMENTS                      REFERENCES
! ---------                       ----------
! 



! Effective core Potentials 
! ------------------------- 
ECP, c, 2, 3 ;
1; !  f-ul potential 
2,1.000000000,0.000000000;
1; !  s-ul potential 
2,6.401052000,33.121638000;
1; !  p-ul potential 
2,7.307747000,-1.986257000;
1; !  d-ul potential 
2,5.961796000,-9.454318000;
ECP, o, 2, 3 ;
1; !  f-ul potential 
2,1.000000000,0.000000000;
1; !  s-ul potential 
2,10.445670000,50.771069000;
1; !  p-ul potential 
2,18.045174000,-4.903551000;
1; !  d-ul potential 
2,8.164798000,-3.312124000;
ECP, al, 10, 3 ;
1; !  f-ul potential 
2,1.000000000,0.000000000;
1; !  s-ul potential 
2,2.198225000,20.409813000;
1; !  p-ul potential 
2,1.601395000,8.980495000;
1; !  d-ul potential 
2,1.499026000,-1.970411000;
}
 
{rks,pbe}

{matrop
LOAD,one_int,H0;print,one_int
READ,emb_int,FILE=vemb.molpro;print,emb_int
ADD,H0,one_int,emb_int;print,H0
SAVE,H0,1200.1,h0
}


{rks,pbe,maxit=200 
gridprint,grid=2
start,2100.2
expec,EKIN
accu,28}

{matrop;
load,EKIN;
LOAD,one_int,H0,1200.1;print,one_int
add,EPOT,-1,EKIN,1,one_int;print,EPOT   
add,VS,1,EPOT,-1,EPOT
save,VS,7100.2,square
load,d,DEN;print,d
save,d,6400.2,DENSITY
}


{cube,h4-mcscf.cube,-1,200,170,140;
step,0.095,0.095,0.095;
orbital,occ}
{matrop;
load,VSM,square,7100.1;print,VSM
load,IM2,square,7200.1;print,IM2
load,VXC,square,7900.1;print,VXC
load,d,DEN;
COUL,J,d;print,J
add,test,1,IM2,1,VSM,-2,J,-1,VXC;print,test
save,test,7900.2,square;
load,H0
load,EKIN
add,test1,1,H0,-1,EKIN;
trace,e_ion2,test,d
}

