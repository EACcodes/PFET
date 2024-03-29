      subroutine cube
      USE molpro_intrinsic
      USE xmloutput
      USE molpro_options, ONLY : xml_output,molpro_pwd
      implicit double precision (a-h,o-z)
c...  cube,filename,iflag,n1,n2,n3
c...  origin,x,y,z
c...  axis,xx,yy,zz
c...  density,
c...  orbital,
c...  potential,
c...  bragg,braggscale .. scales bragg radius
      character(255) :: gopenmol_command = 'rungOpenMol'
      character(4) :: suffix
      logical :: interact
      integer, parameter :: iunit0=22, maxunit=70
      integer, dimension(1:maxunit) :: handle
      integer, dimension(1:3) :: handled
      integer, dimension(1:2) :: handlep
      character(17), dimension(1:3),parameter :: density_name=
     & (/'Density          ',
     &   'Density gradient ',
     &   'Density laplacian'/),
     & density_ext=
     & (/'density          ',
     &   'gradient         ',
     &   'laplacian        '/)
      character(18), dimension(1:2),parameter :: potential_name=
     & (/'Electric potential',
     &   'Electric field    '/),
     & potential_ext=
     & (/'potential         ',
     &   'field             '/)
      integer, external :: gopenmol_open
      include "common/shell_command"
      parameter (ndebug=-1)
      parameter (zall=-1d0,zhomo=-2d0,zlumo=-3d0,zocc=-4d0)
      parameter (fermiocc=1d0)
      integer eta,contrc
      character(16) :: command
      character*16 test,tname
      character*11 forma
      character*255 filename,file
      character(255), dimension(maxunit) :: filenames
      character*80 type
      include "common/maxbfn"
      include "common/code"
      include "common/corb"
      include "common/cbas"
      include "common/etig"
      include "common/big"
      include "common/tapes"
      include "common/cmpp"
      include "common/cgeom"
      include "common/czmat"
#include "common/dumpinfor.fh"
      include "common/cdft"
      common/sbragg/ialmet
      logical lorigin,ldensity,lpotential,lorbital,locc,leig,swap_xz
      dimension origin(3),axes(3,3),step(3),ncube(3),displ(3),zincr(3,3)
      dimension zmin(3),zmax(3),axesi(3,3),ipiv(3),temp(3,3)
      real*8 myeval(500),myoccn(500),myhomo,myhomoekt,Vsmat1(250000),
     >       Imat1(250000),myeval2(500),myhomo1,Imatgc1(250000)
      integer iord(400)
      real*8 stack(2,400)
      dimension originout(3),orbitals(maxbfn),iorbitals(maxbfn)
      CHARACTER(LEN=1024) :: title,description
      integer nprm(300),myact,myact2
      title=''
      description=''
      interact=.false.
      call gets(1,command,1)
      if(command(1:5).eq.'BEGIN') command=command(6:)
      write(iout,1) command(1:lenstr(command))
  1   format('1PROGRAM * ',a,' (Write data to grid)'
     >,5x,'Author: P.J. Knowles, 1997')
c...  parse first data line
      call gets(2,filename,1)
      call locase(filename)
      if (filename.eq.' ') then
        write (6,*) 'filename must be given for ',trim(command)
        call fehler
      end if
      call getvar('ANGSTROM',angst,test,ity,nv,1,1)
c..   defaults
      do k=1,3
        step(k)=0d0
      end do
      idftol=12
      braggscale=4.5d0
      ncubedef=80
      iflag=-1
      if (command(1:4).eq.'GOPE') iflag=1
      call inpi(3,iflag)
      ncubex=ncubedef
      do k=1,3
        ncube(k)=ncubex
        call inpi(3+k,ncube(k))
        ncubex=ncube(k)
      end do
      if (ndebug.ge.1) write (6,*)'ncube after input',ncube
      forma='Unformatted'
      if (iflag.lt.0) forma='Formatted'
       ! trim off any trailing suffix
       idot=index_intrinsic(filename,'.',.true.)
       if (idot.gt.index_intrinsic(filename,'/',.true.))
     >     filename(idot:)=' '
       file = filename
      write (iout,201) forma(1:lenstr(forma)),
     >     file(1:lenstr(file))
 201  format(1x,a,' data will be written to files with base name ',a)
      call upcase(forma)
c..   initialize
      call rebas
      call guess_ini
      lorigin=.false.
      lorbital=.false.
      ldensity=.false.
      mdensity=3
      ndensity=5
      lpotential=.true.
      mpotential=1
      npotential=1
      igrad=2
      nvalue=0
c      call fzero (axes,9)
c      call dfill (3,1d0,axes,4)
      naxis=0
c..   options
 100  call inputl(ncol)
      if (ncol.lt.0) goto 102
      call gets(1,test,1)
      if (test.eq.'STEP') then
        do k=1,3
          call inpf(1+k,step(k))
        end do
        goto 100
      else if (test.eq.'ORIGIN') then
       if (command(1:4).eq.'GOPE') call Error(
     &    'Illegal to redefine origin for gOpenMol output','cube')
        lorigin=.true.
        do k=1,3
          call inpf(1+k,origin(k))
        end do
        goto 100
      else if (test.eq.'AXIS') then
       if (command(1:4).eq.'GOPE') call Error(
     &    'Illegal to redefine axes for gOpenMol output','cube')
        naxis=naxis+1
        if (naxis.gt.3) then
          write (6,*) 'too many axes specified in CUBE'
          call fehler
        end if
        zn=0d0
        call getf(2,axes(1,naxis),3)
        zn=dnrm2_X(3,axes(1,naxis),1)
        if (zn.eq.0d0) axes(naxis,naxis)=1d0
        call dscal_X(3,1d0/zn,axes(1,k),1)
        goto 100
      else if (test.eq.'TITLE') then
       call gets(2,title,1)
       goto 100
      else if (test.eq.'DESCRIPTION') then
       call gets(2,description,1)
       goto 100
      else if (test.eq.'DENSITY'.or.test.eq.'GRADIENT'
     >       .or.test.eq.'LAPLACIAN'.or.test.eq.'DIVERGENCE') then
        ldensity=.true.
        denrec=0d0
        call density_inp(denrec,2,ncol)
        type=test
        call locase(type)
        type(1:1)=test(1:1)
        if (test.eq.'LAPLACIAN' .or. test.eq.'DIVERGENCE') then
         mdensity=max(mdensity,3)
        else if (test.eq.'GRADIENT') then
         mdensity=max(mdensity,2)
        else if (test.eq.'DENSITY') then
         mdensity=max(mdensity,1)
        end if
        mdensity=3
        if (mdensity.eq.1) then
         igrad=0
         ndensity=1
         else if (mdensity.eq.2) then
          igrad=1
          ndensity=4
         else if (mdensity.eq.3) then
          igrad=2
          ndensity=5
         end if
        goto 100
      else if (test.eq.'POTENTIAL'.or.test.eq.'FIELD') then
        lpotential=.true.
        denrec=0d0
        call density_inp(denrec,2,ncol)
        type=test
        call locase(type)
        type(1:1)=test(1:1)
        if (test.eq.'FIELD') then
         mpotential=max(mpotential,2)
        else if (test.eq.'POTENTIAL') then
         mpotential=max(mpotential,1)
        end if
        if (mpotential.eq.1) then
         igrad=0
         npotential=1
         else if (mpotential.eq.2) then
          igrad=1
          npotential=4
         end if
        goto 100
      else if (test.eq.'ORBITAL') then
        lorbital=.true.
        orbrec=0d0
        do k=2,ncol
          call geta(k,tname,test,xx,1)
          if (test.eq.'ALL') then
            xx=zall
          elseif (test.eq.'HOMO') then
            xx=zhomo
          elseif (test.eq.'LUMO') then
            xx=zlumo
          elseif (test.eq.'OCC') then
            xx=zocc
          else if(tname.ne.' ') then
            goto 56
          else
            ierr=1
            if(xx.gt.0d0) then
              io=int(xx)
              is=nint((xx-dble(io))*10.d0)
              ierr=0
              if(is.eq.0) then
                if(nsk.eq.1) is=1
                if(nsk.gt.1) ierr=1
              else if(is.gt.nsk.or.is.lt.0) then
                ierr=1
              end if
              if(ierr.eq.0) then
                if(io.gt.nt(is)) ierr=1
              end if
            end if
            if (ierr.gt.0) then
              write(6,'(1x,a,f10.1,3a)') 'orbital=',xx,
     >           '  (Input string=',trim(test),')'
              call error('Illegal orbital specification.'//
     >         ' Orbital record must be given as RECORD=number.file',
     >         'cube')
             end if
          endif
          nvalue=nvalue+1
          orbitals(nvalue)=xx
        end do
 56     call guess_inp(orbrec,k,ncol)
        type='Orbitals'
        if (nvalue.le.0) then
          nvalue=1
          orbitals(nvalue)=zhomo
        end if
        goto 100
      else if (test.eq.'POTENTIAL') then
        type='not yet implemented'
        goto 100
      else if (test.eq.'BRAGG') then
        call inpf(2,braggscale)
        goto 100
      else if (test.eq.'THR') then
        call inpi(2,idftol)
        write (iout,41) idftol
 41     format(1x,'Density cutoff 10**(-',i2,')')
        goto 100
      else if (test(1:5).eq.'INTER') then
       call inpa(2,type,gopenmol_command,xxx)
       interact=.true.
        goto 100
      else if (test(1:5).eq.'BATCH') then
       interact=.false.
        goto 100
      end if
      call backspace_inp
 102  continue
        swap_xz= command(1:4).eq.'GOPE' ! gopenmol requires x on the innermost loop!
c
c...  default action if not specified
      if (command.eq.'CUBE' .and. ndensity.eq.0 .and. nvalue.eq.0
     &     .and. npotential.eq.0) then
        nvalue=0
        type='Density'
        ldensity=.true.
        mdensity=1
        ndensity=1
        igrad=0
      end if
!      if (command.eq.'CUBE' .and. ndensity*nvalue.ne.0) call Error(
!     &   'Cannot put both orbitals and density in a CUBE file','cube')
      !write (iout,'('' Calculate:'',T19,A)') type(1:lenstr(type))
c...  fill in default axes
      if (swap_xz) then
       ncube3=ncube(3)
       ncube(3)=ncube(1)
       ncube(1)=ncube3
      end if
      if (naxis.lt.1) then
        axes(1,1)=1d0
        axes(2,1)=0d0
        axes(3,1)=0d0
        if (swap_xz) then
         axes(1,1)=0d0
         axes(3,1)=1d0
        end if
      endif
      if (naxis.lt.2) then
        if (swap_xz) then
         axes(3,2)=-axes(2,1)
         axes(2,2)=axes(3,1)
         axes(1,2)=0d0
        else
         axes(1,2)=-axes(2,1)
         axes(2,2)=axes(1,1)
         axes(3,2)=0d0
        end if
      endif
      if (naxis.lt.3) then
        axes(1,3)=axes(2,1)*axes(3,2)-axes(3,1)*axes(2,2)
        axes(2,3)=axes(3,1)*axes(1,2)-axes(1,1)*axes(3,2)
        axes(3,3)=axes(1,1)*axes(2,2)-axes(2,1)*axes(1,2)
        if (swap_xz) call dscal_X(3,-1d0,axes(1,3),1)
      end if
c...  normalize (but not orthogonalize) axes
      do k=1,3
        ss=dnrm2_X(3,axes(1,k),1)
        call dscal_X(3,1d0/ss,axes(1,k),1)
      end do
c...  determine bounding parallelopiped at braggscale bragg radii
c     outside all atoms
      if (ndebug.ge.6) call outsqr (axes,3,3,3,'axes')
      call fmove (axes,axesi,9)
      ierr = 0
      call dgetrf_x(3,3,axesi,3,ipiv,ierr)
      if (ierr.ne.0) then
        write (6,*) 'Linear dependent axes in CUBE'
        call outsqr (axes,3,3,3,'axes')
        call fehler
      end if
      ierr = 0
      call dgetri_x(3,axesi,3,ipiv,temp,9,ierr)
      do k=2,3
        do l=1,k-1
          tt=axesi(k,l)
          axesi(k,l)=axesi(l,k)
          axesi(l,k)=tt
        end do
      end do
      if (ndebug.ge.1) then
        call outsqr (axes,3,3,3,'axes')
        call outsqr (axesi,3,3,3,'axesi')
        do k=1,3
          do l=1,3
            write (iout,*) k,l,ddot_X(3,axes(1,k),1,axesi(1,l),1)
          end do
        end do
      end if
      ialmet=1
      do k=1,3
        zmax(k)=-999d0
        zmin(k)=999d0
        do icen=1,zncen
          numatt=numat(ztag(icen),test)
          dis=ddot_X(3,axesi(1,k),1,zcoord(1,icen),1)
          if (ndebug.gt.3) write(6,'(a,2i3,4f13.7)')'k,icen,zcoord,dis '
     >         ,k,icen,(zcoord(i,icen),i=1,3),dis
          zmax(k)=max(zmax(k),dis+bragg(numatt)*braggscale)
          zmin(k)=min(zmin(k),dis-bragg(numatt)*braggscale)
        end do
      end do
      if (ndebug.gt.3) then
        call outvec(zmin,3,'zmin')
        call outvec(zmax,3,'zmax')
      end if
      if (.not.lorigin) then
c...   set origin at centroid of bounding polyhedron
        call mxva(axes,1,3, zmax,1, origin,1, 3,3)
        call mxvb(axes,1,3, zmin,1, origin,1, 3,3)
        call dscal_X(3,0.5d0,origin,1)
        lorigin=.true.
      end if
c...    determine step from number of points, and adjust aspect ratios
      stepdef=((zmax(1)-zmin(1))*(zmax(2)-zmin(2))*(zmax(3)-zmin(3)))
     >     **(1d0/3d0) /dble(ncubedef-1)
      do k=1,3
        if (step(k).eq.0d0) then
          if (ncube(k).eq.ncubedef) then
            step(k)=stepdef
            ncube(k)=int((zmax(k)-zmin(k))/step(k)+1d0)
          else if (ncube(k).gt.1) then
            step(k)=(zmax(k)-zmin(k))/dble(ncube(k)-1)
          else
            step(k)=0d0
          endif
        endif
      end do
      if (ndebug.ge.1) write (6,*)'ncube after adjust',ncube
      write (iout,200) ncube,origin,axes,step
 200  format(' Grid dimensions:',t19,3i15
     >      /' Grid centroid:',t19,3f15.7/' Axes:',3(t19,3f15.7/)
     >      ,' Grid spacing:',t19,3f15.7)
c....load property matrices
      imo=icorr(0)
c      if (ndensity.gt.0 .or. npotential.gt.0) then
       idensq1=icorr(ntqg)
       iden=icorr(ntdg)
       iter=icorr(2)
       call readm(q(iter),2,2,7100,0,str)
       if ((q(iter).eq.0d0.and.q(iter+1).eq.0d0)) then
          call get_den(q(iden),6400,2,1,1)
       else
          call get_den(q(iden),0,0,0,1)
       endif
c       call get_den(q(iden),2140,2,4,1)
c       call dscal_X(ntdg,2d0,q(iden),1)
c       call readm(q(idensq1),ntqg,2,6400,0,str)
c       call redu(q(idensq1),q(iden),ntg)
c      end if
      if (nvalue.gt.0) then
        irec1=guess_record
        ifil1=guess_file
        if(irec1.eq.0) then
          irec1=wf(1)/10
          ifil1=wf(1)-irec1*10
        end if
        call get_info(irec1,ifil1,0,idiff)
        if (idiff.ne.0) then
          write (6,*) 'Problem with basis dimensions'
          call fehler
        end if
        iset1=0
        call search_dump(irec1,ifil1,'ORBITALS',
     >       guess_set,guess_type,guess_ntype,guess_state,
     >       guess_sym,guess_ms2,guess_nelec,2,
     >       itype,iset1,iset_first,iset_last,idiff)
        if (iset1.eq.0) call fehler
        imo=icorr(ntqg)
        call get_orb(q(imo),irec1,ifil1,iset1,1)
        if (ndebug.ge.2) call druckm(q(imo),1,0,'mo',0)
!ftc if old
!ftc ;c...  see whether we need to look up occupation numbers and eigenvalues
!ftc ;        locc=.false.
!ftc ;        leig=.false.
!ftc ;! we always do now, for the xml dump
!ftc ;        locc=.true.
!ftc ;        leig=.true.
!ftc end
! obtain occupation numbers and eigenvalues only if they're there
        iset2=iset1
        call search_dump(irec1,ifil1,'EIG',
     >       guess_set,guess_type,guess_ntype,guess_state,
     >       guess_sym,guess_ms2,guess_nelec,0,
     >       itype,iset2,iset_first,iset_last,idiff)
        leig = iset2.ne.0
        iset2=iset1
        call search_dump(irec1,ifil1,'OCC',
     >       guess_set,guess_type,guess_ntype,guess_state,
     >       guess_sym,guess_ms2,guess_nelec,0,
     >       itype,iset2,iset_first,iset_last,idiff)
        locc = iset2.ne.0
        if (ndebug.ge.2) call outvec (orbitals,nvalue,'orbitals')
        do k=1,nvalue
          locc=locc.or.orbitals(k).lt.-1d0
          leig=leig.or.orbitals(k).eq.zhomo.or.orbitals(k).eq.zlumo
        end do
        leig=.true.
        if (leig) then
          ieig=icorr(ntg)
c          ieig1=icorr(ntg)
c          call get_eig(q(ieig1),2100,2,1,1)
          call get_eig(q(ieig),irec1,ifil1,iset1,1)
          if (ndebug.ge.1) call outvec(q(ieig),ntg,'eig')
        end if
        locc= .true.
        if (locc) then
          ioccn=icorr(ntg)
          call get_occ(q(ioccn),irec1,ifil1,iset1,1)
          if (ndebug.ge.1) call outvec(q(ioccn),ntg,'occ')
        end if
c...  now process special orbital specifications
        kk=0
 70     kk=kk+1
        if (kk.gt.nvalue) goto 71
          if (orbitals(kk).eq.zall) then
            do k=kk+1,nvalue
              orbitals(k+ntg-1)=orbitals(k)
            end do
            nvalue=nvalue+ntg-1
            do ks=1,nskcp
              do k=1,nt(ks)
                orbitals(kk)=dble(k)+0.1d0*dble(ks)
                kk=kk+1
              end do
            end do
            kk=kk-1
          else if (orbitals(kk).eq.zocc) then
            nshift=0
            do k4=1,ntg
              if (abs(q(ioccn-1+k4)).gt.1d-9) nshift=nshift+1
            end do
            do k=kk+1,nvalue
              orbitals(k+nshift-1)=orbitals(k)
            end do
            nvalue=nvalue+nshift-1
            k4=0
            do ks=1,nskcp
              do k=1,nt(ks)
                k4=k4+1
                if (abs(q(ioccn-1+k4)).gt.1d-9) then
                  orbitals(kk)=dble(k)+0.1d0*dble(ks)
                  kk=kk+1
                end if
              end do
            end do
            kk=kk-1
          else if (orbitals(kk).eq.zhomo) then
            eigmax=-99999d0
            kkk=0
            do ks=1,nsk
              do k=1,nt(ks)
                eigv=q(ieig+kkk)
                if(abs(q(ioccn+kkk)).ge.fermiocc.and.eigv.gt.eigmax)then
                  kssave=ks
                  ksave=k
                  eigmax=eigv
                endif
                kkk=kkk+1
              end do
            end do
            orbitals(kk)=dble(ksave)+0.1d0*dble(kssave)
          else if (orbitals(kk).eq.zlumo) then
            eigmin=99999d0
            kkk=0
            do ks=1,nsk
              do k=1,nt(ks)
                eigv=q(ieig+kkk)
                if(abs(q(ioccn+kkk)).lt.fermiocc.and.eigv.lt.eigmin)then
                  kssave=ks
                  ksave=k
                  eigmin=eigv
                endif
                kkk=kkk+1
              end do
            end do
            orbitals(kk)=dble(ksave)+0.1d0*dble(kssave)
          else
c            write (6,*) 'unimplemented feature',orbitals(kk)
c            call fehler
          end if
        goto 70
 71     continue
        write (iout,75) (orbitals(k),k=1,nvalue)
 75     format(' Orbitals to be computed: ',(t27,10f5.1))
        do k=1,nvalue
         iorb=int(orbitals(k)+.0001d0)
         isym=nint((orbitals(k)-dble(iorb))*10d0)
         iorbitals(k)=iorb+nts(isym)
        end do
       end if

       if (iprocs.ne.0) return

       suffix='plt'
       if (command.eq.'CUBE') suffix='cube'
c...  assign files
       iunit=iunit0
! density plt files
       do kk=1,mdensity
        write (filename,'(A,''_'',A,''.'',A)')
     &     file(1:lenstr(file)),
     &     density_ext(kk)(1:lenstr(density_ext(kk))),trim(suffix)
        write (iout,4461) density_name(kk)(1:lenstr(density_name(kk))),
     &     filename(1:lenstr(filename))
 4461   format(1x,a,' to be written to ',a)
       call opener(handled(kk),filename)
        filenames(kk) = filename
       end do
! potential plt files
       do kk=1,mpotential
        write (filename,'(A,''_'',A,''.'',A)')
     &     file(1:lenstr(file)),
     &     potential_ext(kk)(1:lenstr(potential_ext(kk))),trim(suffix)
        write (iout,4461)
     &     potential_name(kk)(1:lenstr(potential_name(kk))),
     &     filename(1:lenstr(filename))
        call opener(handlep(kk),filename)
        filenames(mdensity+kk) = filename
       end do
! orbital plt files
       nunit=nvalue
       if (nunit.gt.maxunit) call Error('Too many files','cube')
c       do kk=1,nvalue
c         if (orbitals(kk).lt.10d0) then
c          write (filename,'(A,''_orbital_'',f3.1,''.'',A)')
c     &       file(1:lenstr(file)),orbitals(kk),trim(suffix)
c         else if (orbitals(kk).lt.100d0) then
c          write (filename,'(A,''_orbital_'',f4.1,''.'',A)')
c     &       file(1:lenstr(file)),orbitals(kk),trim(suffix)
c         else
c          write (filename,'(A,''_orbital_'',f5.1,''.'',A)')
c     &       file(1:lenstr(file)),orbitals(kk),trim(suffix)
c         end if
c         write (iout,445) orbitals(kk),filename(1:lenstr(filename))
c 445     format(' Orbital',f5.1,' to be written to ',a)
c        call opener(handle(kk),filename)
c        filenames(mdensity+mpotential+kk) = filename
c       end do
c... write header
      if (command.eq. 'CUBE') then
       IF (xml_output) THEN
        CALL xmlNodeBegin(iout, 'cube')
        if (dump_method.ne.' ') CALL xmlNodeAttribute(iout, 'method'
     $       ,dump_method)
        indent = xmlNodeContent(iout)
        do k=1,ndensity
         CALL xmlNodeBegin(iout, 'field')
         CALL xmlNodeAttribute(iout, 'quantity','density')
         CALL xmlNodeAttribute(iout, 'file',
     $        filenames(k))
         CALL xmlNodeEnd(iout)
        end do
        do k=1,npotential
         CALL xmlNodeBegin(iout, 'field')
         CALL xmlNodeAttribute(iout, 'quantity','potential')
         CALL xmlNodeAttribute(iout, 'file',
     $        filenames(mdensity+k))
         CALL xmlNodeEnd(iout)
        end do
        do k=1,nvalue
         idump=0
         do kkk=1,dump_nset
          if (dump_set(kkk).eq.iset1) idump=kkk
         end do
         CALL xmlNodeBegin(iout, 'field')
         CALL xmlNodeAttribute(iout, 'quantity','orbital')
         if (idump.ne.0) then
          CALL xmlNodeAttribute(iout, 'type',dump_type(idump))
         end if
         CALL xmlNodeAttribute(iout, 'number',int(orbitals(k)))
         CALL xmlNodeAttribute(iout, 'symmetry',nint((orbitals(k)
     $        -dble(int(orbitals(k))))*10d0))
         if (locc) CALL xmlNodeAttribute(iout, 'occupancy',
     $        q(ioccn-1+iorbitals(k)))
         myoccn(k)=q(ioccn-1+iorbitals(k))
         if (leig) CALL xmlNodeAttribute(iout, 'energy',
     $        q(ieig-1+iorbitals(k)))
         myeval(k)=q(ieig-1+iorbitals(k))
c         myeval2(k)=q(ieig1-1+iorbitals(k))
         CALL xmlNodeAttribute(iout, 'file',
     $        filenames(mdensity+mpotential+k))
         CALL xmlNodeEnd(iout)
        end do
        CALL xmlNodeBegin(iout, 'dimensions')
        indent = xmlNodeContent(iout)
        write (iout,'(3I8)') ncube
        CALL xmlNodeEnd(iout)
        CALL xmlNodeBegin(iout, 'origin')
        indent = xmlNodeContent(iout)
        write (iout,'(3F15.7)') origin
        CALL xmlNodeEnd(iout)
        CALL xmlNodeBegin(iout, 'axes')
        indent = xmlNodeContent(iout)
        write (iout,'(3F15.7)') axes
        CALL xmlNodeEnd(iout)
        CALL xmlNodeBegin(iout, 'step')
        indent = xmlNodeContent(iout)
        write (iout,'(3F15.7)') step
        CALL xmlNodeEnd(iout)
        CALL xmlNodeEnd(iout)
       END IF
       iunit=iunit0
       do kk=1,npotential+ndensity+nvalue
        lorbital = kk.gt.npotential+ndensity
       do k=1,3
        originout(k)=(origin(k)-0.5d0*(
     >   (step(1)*dble(ncube(1)-1)*axes(k,1))+
     >   (step(2)*dble(ncube(2)-1)*axes(k,2))+
     >   (step(3)*dble(ncube(3)-1)*axes(k,3))))
       enddo
       if (forma.eq.'FORMATTED') then
        if (TRIM(title).eq.'') then
         write (iunit,603) rechn
 603     format(10a8)
        else
         write (iunit,602) TRIM(title)
        endif
        if (TRIM(description).eq.'') then
         write (iunit,602) type
        else
         write (iunit,602) TRIM(description)
        endif
 602    format(a)
        incen=zncen
        if (lorbital) incen=-incen
        write (iunit,601) incen,(originout(k),k=1,3)
 601    format(i5,4f12.6)
       else
        write (iunit) incen,(originout(k),k=1,3)
       endif
       do k=1,3
        if (forma.eq.'FORMATTED') then
         write (iunit,601) ncube(k),(step(k)*axes(i,k),i=1,3)
        else
         write (iunit) ncube(k),(step(k)*axes(i,k),i=1,3)
        endif
       enddo
       do k=1,zncen
        numatt=numat(ztag(k),test)
        if (forma.eq.'FORMATTED') then
         write (iunit,601) numatt,zcharge(k),(zcoord(i,k),i=1,3)
        else
         write (iunit) numatt,zcharge(k),(zcoord(i,k),i=1,3)
        endif
       enddo
       if (lorbital) then
        iorb=nint(orbitals(kk-ndensity-npotential)+.0001d0)
        isym=nint((orbitals(kk-ndensity-npotential)-dble(iorb))*10d0)
        iorb = iorbitals(kk-ndensity-npotential)
        do isym=1,nskcp
         if (iorb.gt.nts(isym)) isymm=isym
        end do
        iorb = (iorb-nts(isymm))*100 + isymm ! eg 2503 for the 25th orbital in symmetry 3
        if (forma.eq.'FORMATTED') then
         write (iunit,6011) 1, iorb
 6011    format(2i5)
        else
         write (iunit,'(2i5)') 1, iorb
        endif
       endif
       iunit = iunit + 1
       end do
      else if (command(1:4).eq.'GOPE') then
! put out .crd file with geometry
       filename=file(1:lenstr(file))//'.crd'
       call intface_do('CRD',filename,'REWIND',' ',0,iprocs.eq.0)
       iunit=iunit0
! density plt files
       do kk=1,mdensity
        if (forma.eq.'FORMATTED') then
         write (handled(kk),*) 3,2
         write (handled(kk),*) ncube
         write (handled(kk),600) (zmin(i)/angst,zmax(i)/angst,i=1,3)
        else
         call gopenmol_fwrite_integer(handled(kk),3,1)
         call gopenmol_fwrite_integer(handled(kk),2,1)
         call gopenmol_fwrite_integer(handled(kk),ncube,3)
         do i=1,3
          call gopenmol_fwrite_real(handled(kk),zmin(i)/angst,1)
          call gopenmol_fwrite_real(handled(kk),zmax(i)/angst,1)
         end do
        end if
       end do
! potential plt files
       do kk=1,mpotential
        if (forma.eq.'FORMATTED') then
         write (handlep(kk),*) 3,2
         write (handlep(kk),*) ncube
         write (handlep(kk),600) (zmin(i)/angst,zmax(i)/angst,i=1,3)
        else
         call gopenmol_fwrite_integer(handlep(kk),3,1)
         call gopenmol_fwrite_integer(handlep(kk),2,1)
         call gopenmol_fwrite_integer(handlep(kk),ncube,3)
         do i=1,3
          call gopenmol_fwrite_real(handlep(kk),zmin(i)/angst,1)
          call gopenmol_fwrite_real(handlep(kk),zmax(i)/angst,1)
         end do
        end if
       end do
! orbital plt files
c       do kk=1,nvalue
c        if (forma.eq.'FORMATTED') then
c         write (handle(kk),*) 3,2
c         write (handle(kk),*) ncube
c         write (handle(kk),600) (zmin(i)/angst,zmax(i)/angst,i=1,3)
c        else
c         call gopenmol_fwrite_integer(handle(kk),3,1)
c         call gopenmol_fwrite_integer(handle(kk),2,1)
c         call gopenmol_fwrite_integer(handle(kk),ncube,3)
c         do i=1,3
c          call gopenmol_fwrite_real(handle(kk),zmin(i)/angst,1)
c          call gopenmol_fwrite_real(handle(kk),zmax(i)/angst,1)
c         end do
c        end if
c       end do
      end if
      mysqr=0
      myvec=0
      nprm=0
      myj=0
      myao2=0
      myprm=nvalue
      myact=myprm
      do k=1,nvalue
         iorb=int(orbitals(k)+.0001d0)
         isym=int((orbitals(k)-dble(iorb))*10d0+.0001d0)
         nprm(isym)=iorb
         if(myoccn(k).eq.2d0) myact=myact-1
      enddo
      myact2=myact**2
      lden2=myact2*(myact2+1)/2
      iden2=icorr(lden2)
c      if(q(iter).eq.0d0)then
c        call readm(q(iecp),ntqg,2,6400,0,str)
c        call outvec(q(iecp),ntqg,"MYECP")
c      endif

c      call readm(q(iden2),lden2,1,7800,0,str)
!      do mysym=1,nsk
!        myn=nt(mysym)
!        do myi=1,myn
!        if (q(ioccn+myi-1+myj).gt.1e-6) then
!           nprm(mysym)=nprm(mysym)+1
!        endif
!        enddo
!        myj=myj+myn
!        myprm=myprm+nprm(mysym)
!      enddo
      ekteig=icorr(myprm)
      gceig=icorr(myprm)
      myx=0
      iord=0
      myhomo=q(gceig)
      myhomo1=myeval(1)
      do k=1,nvalue-1
         if(myhomo1.lt.myeval(1+k))
     >    myhomo1=myeval(1+k)
      enddo
! Shif the energies so that the HOMO energy is a constant
      myhomoekt=-0.228018
      do k=1,nvalue
         myeval(k)=myeval(k)+myhomoekt-myhomo1
      enddo

      Vsmat1=0d0
      Imat1=0d0
      Imatgc1=0d0
      call grid_orbital_initialize(1d-12)
      if (mdensity.gt.0 .or. nvalue.gt.0 .or. mpotential.gt.0) then
      npt=ncube(3)
      mypt=icorr(1)
      call readm(q(mypt),1,1,7700,0,str)
      npt=q(mypt)
      igrd=icorr(npt*3)
      iwts=icorr(npt)
      call readm(q(igrd),npt*3,1,7500,0,str)
      call readm(q(iwts),npt,1,7600,0,str)
      icoord=icorr(3*npt)
      ivalue=icorr(npt*nvalue)
      idensity=icorr(npt*ndensity)
      ipotential=icorr(npt*npotential)
      iorbval=icorr(npt*ntg)
      if (igrad.ge.1) then
        iorbgrad=icorr(npt*ntg*3)
      else
        iorbgrad=iorbval
      end if
      if (igrad.ge.2) then
        iorbhess=icorr(npt*ntg*6)
      else
      iorbhess=iorbval
      endif
      ihelp=icorr(npt*2)
      iorbmed=icorr(ntg)
      do k1=1,1
        displ(1)=0.5d0*step(1)*dble(2*k1-ncube(1)-1)
        do k2=1,1
          displ(2)=0.5d0*step(2)*dble(2*k2-ncube(2)-1)
          do k3=1,1
            displ(3)=0.5d0*step(3)*dble(2*k3-ncube(3)-1)
            call fmove (origin,q(icoord+(k3-1)*3),3)
            call mxvb (axes,1,3, displ,1, q(icoord+(k3-1)*3),1, 3,3)
          end do
c....  evaluation
!=======================QI:MAIN FUNCTION FOR EVALUATION===============
          call cube_evaluate (q(igrd),q(ivalue),q(idensity),
     &       q(ipotential),npt,q(iorbval),
     >       q(iorbgrad),q(iorbhess),
     >       q(iden),q(ihelp),igrad,
     >       q(imo),orbitals,ldensity,lpotential,lorbital,nvalue,
     &       mdensity,mpotential,q(iorbmed),myeval,myoccn,step,
     >       Vsmat1,Imat1,q(gceig),Imatgc1,q(ifocksq2),myprm,q(iwts),
     >       myact, q(iden2),q(iter))
c....  output
          iaddr=idensity
          do kk=1,mdensity
            nblock=npt
c.. dont blame me for the silly output format.. its only to match G94
            if (kk.eq.2) nblock=npt*3
 600         format(6e13.5)
            call writeblock(handled(kk),q(iaddr),nblock)
            iaddr=iaddr+nblock
            if (iaddr.ge.idensity+ndensity*npt) goto 5551
          end do
 5551     continue
          iaddr=ipotential
          do kk=1,mpotential
            nblock=npt
c.. dont blame me for the silly output format.. its only to match G94
            if (kk.eq.2) nblock=npt*3
            call writeblock(handlep(kk),q(iaddr),nblock)
            iaddr=iaddr+nblock
            if (iaddr.ge.ipotential+npotential*npt) goto 5552
          end do
 5552     continue
          iaddr=ivalue
c          do kk=1,nvalue
c            call writeblock(handle(kk),q(iaddr),nblock)
c            iaddr=iaddr+npt
c          end do
         end do
       end do
       do kk=1,mdensity
        call closer(handled(kk))
       end do
       do kk=1,mpotential
        call closer(handlep(kk))
       end do
c       do kk=1,nvalue
c        call closer(handle(kk))
c       end do
      end if
c      call outsqr(Vsmat1,ntg,ntg,ntg,'VS MAT')
      call writem(Vsmat1,ntqg,1,7100,0,'VSM')
      call writem(Imatgc1,ntqg,2,7200,0,'IMGC')
      call writem(Imat1,ntqg,1,7200,0,'IM')
c      call corlsr(ifock)
c      call corlsr(src1)
c      call corlsr(iden3)
      call corlsr(iden2)
      call grid_orbital_term
! attempt to fire up gopenmol
      if (interact) then
       filename=file(1:lenstr(file))//'.crd'
       file=gopenmol_command(1:lenstr(gopenmol_command))//' -c'
     &    //filename
       write (iout,1001) file(1:lenstr(file))
 1001  format(/' Shell command: ',a)
       if (iprocs.eq.0) then
        irc = shell_command(file,molpro_pwd)
       end if
      end if
      return
      contains
      subroutine writeblock(handle,buf,nbuf)
      integer :: handle, nbuf
      real*8, dimension(nbuf) :: buf
      if (command.eq.'CUBE') then
       if (forma.eq.'FORMATTED') then
        write (handle,600) (q(iaddr-1+k),k=1,npt)
       else
        write (handle) (q(iaddr-1+k),k=1,npt)
       end if
      else if (command(1:4).eq.'GOPE') then
       if (forma.eq.'FORMATTED') then
        write (handle,600) (q(iaddr-1+k),k=1,npt)
       else
        call gopenmol_fwrite_real(handle,q(iaddr),npt)
       end if
      end if
 600  format(6e13.5)
      end subroutine writeblock
      subroutine closer(handle)
      integer :: handle
      if (command.eq.'CUBE') then
        close(handle)
      else if (command(1:4).eq.'GOPE') then
       if (forma.eq.'FORMATTED') then
        close(handle)
       else
        call gopenmol_close(handle)
       end if
      end if
      end subroutine closer
      subroutine opener(handle,filename)
      character(*) :: filename
      character(255) :: file
      integer :: handle
      if(filename(1:1).ne.'/') then
        file=molpro_pwd(1:lenstr(molpro_pwd))//filename
      else
        file=filename
      end if
      if (command.eq.'CUBE' .or. forma.eq.'FORMATTED') then
       open (iunit,form=forma,err=301,file=file)
       handle = iunit
       iunit = iunit + 1
      else
       handle = gopenmol_open(file)
      end if
      return
 301  Call Error('Error in opening file','cube')
      end subroutine opener
      end
      subroutine cube_evaluate(coord,value,density,potential,npt,
     &   orbval,orbgrad,orbhess,
     >     den,help,igrad,
     >     zmo,orbitals,ldensity,lpotential,lorbital,nvalue,mdensity,
     &   mpotential,orbmed,myeval1,myocc,mystep,Vsmat,Imat,
     >   mygcval,Imatgc,gfock,myprm,wts,myact,myden2,iter)
      implicit double precision (a-h,o-z)
      include "common/bas"
      include "common/tapes"
      dimension coord(3,*),value(npt,*),density(npt,*),potential(npt,*),
     >     orbval(npt,ntg),orbgrad(npt,ntg,3),orbhess(npt,ntg,6),
     >     gfock(*),wts(*),iter(*)
      real*8 myeval1(ntg),myI(npt),myTau(npt),myden(npt),psi(npt,ntg),
     >       psi1D(npt,ntg,3),nabla(npt)
      real*8 myden2(*),nabla1(npt),
     >       mystep(3),nabla2(npt)
      real*8 mygcval(*),Imatgc(ntqg)
      dimension den(ntdg),help(npt,2),orbitals(*),zmo(*),orbmed(ntg)
      real*8 myocc(ntg),Vsmat(ntqg),Imat(ntqg)
      logical ldensity,lorbital,lpotential
      integer numorb(nsk),mysqr,myder,myact
      real*8 myij,myji,myhelp,myhelp1
      call grid_orbital_values(npt,igrad,coord,orbval,orbgrad,orbhess)
c      call esp_grid_trace('POT',0,coord,npt,
c     &        den,potential)
c       endif
       
       call dft_rho(npt,orbval,orbgrad,orbhess,den,density,density(1,2),
     >     density(1,5),help,help(1,2),igrad,orbmed)
      nabla1=0d0
      nabla2=0d0
      do igrid=1,npt
        nabla1(igrid)=0.25*density(igrid,5)
        do myder=2,4
           nabla2(igrid)=nabla2(igrid)-0.125*density(igrid,myder)**2
        enddo
      enddo

      if (lorbital) then
        numorb=0
        psi=0d0
        psi1D=0d0
        do k=1,nvalue
          iorb=int(orbitals(k)+.0001d0)
          isym=int((orbitals(k)-dble(iorb))*10d0+.0001d0)
          if (isym.lt.1. or. isym.gt.nsk .or. iorb.gt.nt(isym)) then
            write (6,'(a,f7.1)') 'Invalid orbital:',orbitals(k)
            call fehler
          end if
!===================QI: OBTAIN MO ORBITALS  ======================
!===================psi: NATURAL ORBITALS    ======================
          call mxva(orbval(1,1+nts(isym)),1,npt,
     >         zmo(ntq(isym)+(iorb-1)*nt(isym)+1),1,
     >         psi(1,k),1,  npt,nt(isym))
             do myder=1,3
          call mxva(orbgrad(1,1+nts(isym),myder),1,npt,
     >         zmo(ntq(isym)+(iorb-1)*nt(isym)+1),1,
     >         psi1D(1,k,myder),1,  npt,nt(isym))
             enddo
        end do

      myI=0d0
      myTau=0d0
      myden=0d0
      nabla=0d0      
      call copym(density(:,1),1,myden,1,1,npt)
c      do igrid=1,npt
c         myden(igrid)=density(igrid,1)
c      enddo
c      do k=1,nvalue
c       do igrid=1,npt
c         iorb=int(orbitals(k)+.0001d0)
c         isym=int((orbitals(k)-dble(iorb))*10d0+.0001d0)
c         ibas=1+nts(isym)
c         write(*,*)'orbital value order2=', orbval(1,ibas)
c         write(*,*)'orbital value=', orbval(igrid,ibas)
c       enddo
c      enddo
!===================QI:CONSTRUCT I, \TAU,\TAU_L  ======================
      do igrid=1,npt
          if(myden(igrid).lt.1e-16) then
            myden(igrid)=1e-16
          endif 
          nabla1(igrid)=nabla1(igrid)/myden(igrid)
          nabla2(igrid)=nabla2(igrid)/myden(igrid)**2
          nabla(igrid)=nabla1(igrid)+nabla2(igrid)
        do k=1,nvalue
          myI(igrid)=myI(igrid)
     >               +myocc(k)*
     >    myeval1(k)*psi(igrid,k)*psi(igrid,k)/myden(igrid)
         do j=k+1,nvalue
            myij=0d0
            myji=0d0
           do myder=1,3
              myij=psi(igrid,k)*psi1D(igrid,j,myder)
             myji=psi(igrid,j)*psi1D(igrid,k,myder)
             myTau(igrid)=myTau(igrid)
     >    +0.5*myocc(k)*myocc(j)*(myij-myji)*(myij-myji)
     >   /myden(igrid)**2
            enddo
          enddo
        enddo
      enddo
!===================QI:CONSTRUCT SLATER POTENTIAL======================

c      do k=1,ntg
      do igrid=1,npt
        if(iter(1).eq.0d0)then
c           write(*,*) myden(igrid),nabla(igrid),
c     >    2*myIgc(igrid)-myTau(igrid)
c           write(*,*) orbval(igrid,k)
c           write(*,*) nabla(igrid),potential(igrid,1),
c     >     myI(igrid)-myTau(igrid)
            write(*,*) density(igrid,1),nabla(igrid)
        endif 
       enddo
c      enddo
      mysq=0
      myn=0
c      do i=1,ntg
c        do igrid=1,npt
c         if(iter(1).eq.0d0)
c     >     buff1(i,igrid)=nabla(igrid)*wts(igrid)*orbval(igrid,i)
c         buff2(i,igrid)=(myI(igrid)-myTau(igrid))*wts(igrid)
c     >   *orbval(igrid,i)
c        enddo
c      enddo
c      if(iter(1).eq.0d0)
c     >    call mxma(buff1,1,ntg,orbval,1,npt,Vsmat,1,ntg,ntg,npt,ntg)
c      call mxma(buff2,1,ntg,orbval,1,npt,Imat,1,ntg,ntg,npt,ntg)
!===================QI:TRANSFER TO AO BASIS ============================
      do isym=1,nsk
         n=nt(isym)
         do i=1,n
            do j=1,n
               do igrid=1,npt
              if(iter(1).eq.0d0)
     >          Vsmat((i-1)*n+j+mysq)=Vsmat((i-1)*n+j+mysq)
     >         +(nabla(igrid))*orbval(igrid,i+myn)
     >         *orbval(igrid,j+myn)*wts(igrid)
                Imat((i-1)*n+j+mysq)=Imat((i-1)*n+j+mysq)
     >         +(myI(igrid)-myTau(igrid))*orbval(igrid,i+myn)
     >         *orbval(igrid,j+myn)*wts(igrid)
               enddo
            enddo
         enddo
         mysq=mysq+n*n
         myn=myn+n
      enddo
      end if
      return
      end

