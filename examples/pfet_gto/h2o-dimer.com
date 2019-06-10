 memory,3000,m
 symmetry,NOSYM
 geometry={
 Al1  8.0929600000E+00 4.0464800000E+00 -2.3500188843E-15
 Al2  8.0929600000E+00 6.0697200000E+00 -2.0232400000E+00
 Al3  1.0116200000E+01 4.0464800000E+00 -2.0232400000E+00
 Al4  6.0697200000E+00 4.0464800000E+00 -2.0232400000E+00
 Al5  8.0929600000E+00 2.0232400000E+00 -2.0232400000E+00
 Al6  8.0929600000E+00 4.0464800000E+00 -4.0464800000E+00
 Al7  6.0697200000E+00 6.0697200000E+00 -3.2900264381E-15
 Al8  1.0116200000E+01 2.0232400000E+00 -9.4000755373E-16
 Al9  1.0116200000E+01 6.0697200000E+00 -4.0464800000E+00
 Al10 6.0697200000E+00 2.0232400000E+00 -1.8800151075E-15
 Al11 6.0697200000E+00 6.0697200000E+00 -4.0464800000E+00
 Al12 1.0116200000E+01 2.0232400000E+00 -4.0464800000E+00
 C1  9.46019384628 5.41371384628 -0.65600615372
 O1  10.114909231 6.06842923101 -0.00129076898569
 }
 
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
 
{rks,pbe ,maxit=200
 accu,28 
 natorb,2110.2
 gridprint,grid=2}

{matrop,
READ,emb_int,FILE=vemb.molpro
READ,myden1,FILE=myden1.molpro
READ,myden2,FILE=myden2.molpro
add,myden,myden1,myden2;print,myden
trace,e_emb,emb_int,myden
save,myden,6400.2,DENSITY
save,myden,6500.2,DENSITY
load,H0;
load,EKIN
add,test,1,H0,-1,EKIN;print,test}

{dft,pbe  
density,6400.2
potential,8100.1}

 {matrop;
 load,d,DEN,6400.2
 coul,j,d;
 trace,ej_tot,j,d;
 save,j,6300.1,square
 load,EPOT
 add,VS,1,EPOT,-1,EPOT
 save,VS,7100.2,square
 }
 
 {cube,he-mcscf.cube,-1,200,170,140;
 step,0.095,0.095,0.095;
 orbital,occ}
 
 {matrop;
 load,VSM,square,7100.1;print,VSM
 load,d,DEN,6400.2;print,d
 COUL,J,d;
 add,VSM,1,VSM,-2,J
 save,VSM,7100.3,square
 }
 
 {rks,pbe,maxit=200 
  start,2110.2
  accu,28
  natorb,2110.2}
 {matrop,
 load,d,DEN
 save,d,6400.2;DENSITY
 }

 {cube,he-mcscf.cube,-1,200,170,140;
 step,0.095,0.095,0.095;
 orbital,occ}
 
 {matrop;
 load,VSM,square,7100.1;print,VSM
 load,IM2,square,7200.1;print,IM2
 load,VXC,square,7900.1;print,VXC
 load,d,DEN;
 COUL,J,d;print,J
 add,test,1,IM2,1,VSM,-2,J,-1,VXC;print,test
 save,test,7900.3,square
 load,VSM,square,7100.3
 add,VSM,1,VSM,-1,test
 save,VSM,7100.2,square
 add,VS,1,VSM,1,IM2; 
 save,VS,7400.1,square
 }

 
 
 {rhf,maxit=200
  accu,28
  start,2110.2}
 
 do n=1,8000
 E1=energy
 {cube,he-mcscf.cube,-1,200,170,140;
 step,0.095,0.095,0.095;
 orbital,occ}
 {matrop;
 load,VSM,square,7100.2;
 load,IM2,square,7200.1;
 add,VS,1.0,VSM,1.0,IM2;
 load,VS_old,square,7400.1;
 add,VS,0.2,VS,0.8,VS_old;
 save,VS,7400.1,square;
 }
 {rhf,maxit=200
  accu,28
  start,2110.2}
 E2=energy
 deltaE=(E1-E2)*(E1-E2)
 if(deltaE.lt.1e-16) then
   {matrop;
   load,vs_final,square,7400.1
   load,H0,h0,1200.1
   READ,emb_int,FILE=vemb.molpro
   load,EKIN
   add,EPOT,1,H0,-1,EKIN
   load,d,DEN;
   trace,ek_tot,EKIN,d
   trace,e_iontot,EPOT,d
   coul,vj,d
   load,test,square,7900.3
   add,vs_final,1,vs_final,2,vj;print,vs_final
   READ,VS,FILE=vemb_f.molpro
   save,VS,7100.2,square
   load,vxc_tot,triang,8100.1
   save,vxc_tot,8100.1,square
   load,vxc_tot,square,8100.1
   read,vxc_sys1,file=vxc_sys1.molpro
   read,vj_sys1,file=vj1.molpro
   read,vj_sys2,file=vj2.molpro
   read,vion_sys1,file=vex1.molpro
   read,vion_sys2,file=vex2.molpro
   READ,myden1,FILE=myden1.molpro
   READ,myden2,FILE=myden2.molpro
   trace,ej_sys1,vj_sys1,myden1
   trace,ej_sys2,vj_sys2,myden2
   trace,e_ion1,vion_sys1,myden2
   trace,e_ion2,vion_sys2,myden1
   load,vj_tot,square,6300.1
   add,fun_der2,2,vj_tot,1,vxc_tot,-1,vs_final;print,fun_der2
   add,fun_der1,2,vj_tot,1,vxc_tot,-1,vs_final,-2,vj_sys1,-1,vxc_sys1;print,fun_der1
   }
   {cube,he-mcscf.cube,-1,200,170,140;
   step,0.095,0.095,0.095;
   orbital,occ}
   n=8000
 end if
 enddo

