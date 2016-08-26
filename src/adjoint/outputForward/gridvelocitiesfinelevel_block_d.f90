!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of gridvelocitiesfinelevel_block in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: *sfacei *sfacej *s *sfacek
!   with respect to varying inputs: gammainf pinf timeref rhoinf
!                veldirfreestream machgrid *x *si *sj *sk
!   plus diff mem management of: sfacei:in sfacej:in s:in sfacek:in
!                x:in si:in sj:in sk:in
subroutine gridvelocitiesfinelevel_block_d(useoldcoor, t, sps)
!
!       gridvelocitiesfinelevel computes the grid velocities for       
!       the cell centers and the normal grid velocities for the faces  
!       of moving blocks for the currently finest grid, i.e.           
!       groundlevel. the velocities are computed at time t for         
!       spectral mode sps. if useoldcoor is .true. the velocities      
!       are determined using the unsteady time integrator in           
!       combination with the old coordinates; otherwise the analytic   
!       form is used.                                                  
!
  use blockpointers
  use cgnsgrid
  use flowvarrefstate
  use inputmotion
  use inputunsteady
  use iteration
  use inputphysics
  use inputtsstabderiv
  use monitor
  use communication
  use utils_d, only : tsalpha, tsbeta, tsmach, terminate, &
& rotmatrixrigidbody
  implicit none
!
!      subroutine arguments.
!
  integer(kind=inttype), intent(in) :: sps
  logical, intent(in) :: useoldcoor
  real(kind=realtype), dimension(*), intent(in) :: t
!
!      local variables.
!
  integer(kind=inttype) :: nn, mm
  integer(kind=inttype) :: i, j, k, ii, iie, jje, kke
  real(kind=realtype) :: oneover4dt, oneover8dt
  real(kind=realtype) :: oneover4dtd, oneover8dtd
  real(kind=realtype) :: velxgrid, velygrid, velzgrid, ainf
  real(kind=realtype) :: velxgridd, velygridd, velzgridd, ainfd
  real(kind=realtype) :: velxgrid0, velygrid0, velzgrid0
  real(kind=realtype) :: velxgrid0d, velygrid0d, velzgrid0d
  real(kind=realtype), dimension(3) :: sc, xc, xxc
  real(kind=realtype), dimension(3) :: scd, xcd, xxcd
  real(kind=realtype), dimension(3) :: rotcenter, rotrate
  real(kind=realtype), dimension(3) :: rotrated
  real(kind=realtype), dimension(3) :: rotationpoint
  real(kind=realtype), dimension(3, 3) :: rotationmatrix, &
& derivrotationmatrix
  real(kind=realtype), dimension(3, 3) :: derivrotationmatrixd
  real(kind=realtype) :: tnew, told
  real(kind=realtype), dimension(:, :), pointer :: sface
  real(kind=realtype), dimension(:, :), pointer :: sfaced
  real(kind=realtype), dimension(:, :, :), pointer :: xx, ss
  real(kind=realtype), dimension(:, :, :), pointer :: xxd, ssd
  real(kind=realtype), dimension(:, :, :, :), pointer :: xxold
  integer(kind=inttype) :: liftindex
  real(kind=realtype) :: alpha, beta, intervalmach, alphats, &
& alphaincrement, betats, betaincrement
  real(kind=realtype) :: alphad, betad, alphatsd, betatsd
  real(kind=realtype), dimension(3) :: veldir
  real(kind=realtype), dimension(3) :: veldird
  real(kind=realtype), dimension(3) :: refdirection
  intrinsic sqrt
  real(kind=realtype) :: arg1
  real(kind=realtype) :: arg1d
! compute the mesh velocity from the given mesh mach number.
! vel{x,y,z}grid0 is the actual velocity you want at the
! geometry. 
  arg1d = ((gammainfd*pinf+gammainf*pinfd)*rhoinf-gammainf*pinf*rhoinfd)&
&   /rhoinf**2
  arg1 = gammainf*pinf/rhoinf
  if (arg1 .eq. 0.0_8) then
    ainfd = 0.0_8
  else
    ainfd = arg1d/(2.0*sqrt(arg1))
  end if
  ainf = sqrt(arg1)
  velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(1)) - &
&   ainf*machgrid*veldirfreestreamd(1)
  velxgrid0 = ainf*machgrid*(-veldirfreestream(1))
  velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(2)) - &
&   ainf*machgrid*veldirfreestreamd(2)
  velygrid0 = ainf*machgrid*(-veldirfreestream(2))
  velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(3)) - &
&   ainf*machgrid*veldirfreestreamd(3)
  velzgrid0 = ainf*machgrid*(-veldirfreestream(3))
! compute the derivative of the rotation matrix and the rotation
! point; needed for velocity due to the rigid body rotation of
! the entire grid. it is assumed that the rigid body motion of
! the grid is only specified if there is only 1 section present.
  call derivativerotmatrixrigid_d(derivrotationmatrix, &
&                           derivrotationmatrixd, rotationpoint, t(1))
!compute the rotation matrix to update the velocities for the time
!spectral stability derivative case...
  if (tsstability) then
! determine the time values of the old and new time level.
! it is assumed that the rigid body rotation of the mesh is only
! used when only 1 section is present.
    tnew = timeunsteady + timeunsteadyrestart
    told = tnew - t(1)
    if ((tspmode .or. tsqmode) .or. tsrmode) then
! compute the rotation matrix of the rigid body rotation as
! well as the rotation point; the latter may vary in time due
! to rigid body translation.
      call rotmatrixrigidbody(tnew, told, rotationmatrix, rotationpoint)
      if (tsalphafollowing) then
        velxgrid0d = rotationmatrix(1, 1)*velxgrid0d + rotationmatrix(1&
&         , 2)*velygrid0d + rotationmatrix(1, 3)*velzgrid0d
        velxgrid0 = rotationmatrix(1, 1)*velxgrid0 + rotationmatrix(1, 2&
&         )*velygrid0 + rotationmatrix(1, 3)*velzgrid0
        velygrid0d = rotationmatrix(2, 1)*velxgrid0d + rotationmatrix(2&
&         , 2)*velygrid0d + rotationmatrix(2, 3)*velzgrid0d
        velygrid0 = rotationmatrix(2, 1)*velxgrid0 + rotationmatrix(2, 2&
&         )*velygrid0 + rotationmatrix(2, 3)*velzgrid0
        velzgrid0d = rotationmatrix(3, 1)*velxgrid0d + rotationmatrix(3&
&         , 2)*velygrid0d + rotationmatrix(3, 3)*velzgrid0d
        velzgrid0 = rotationmatrix(3, 1)*velxgrid0 + rotationmatrix(3, 2&
&         )*velygrid0 + rotationmatrix(3, 3)*velzgrid0
      end if
    else if (tsalphamode) then
! get the baseline alpha and determine the liftindex
      call getdirangle_d(veldirfreestream, veldirfreestreamd, &
&                  liftdirection, liftindex, alpha, alphad, beta, betad)
!determine the alpha for this time instance
      alphaincrement = tsalpha(degreepolalpha, coefpolalpha, &
&       degreefouralpha, omegafouralpha, coscoeffouralpha, &
&       sincoeffouralpha, t(1))
      alphatsd = alphad
      alphats = alpha + alphaincrement
!determine the grid velocity for this alpha
      refdirection(:) = zero
      refdirection(1) = one
      call getdirvector_d(refdirection, alphats, alphatsd, beta, betad, &
&                   veldir, veldird, liftindex)
!do i need to update the lift direction and drag direction as well?
!set the effictive grid velocity for this time interval
      velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(1)) - ainf*&
&       machgrid*veldird(1)
      velxgrid0 = ainf*machgrid*(-veldir(1))
      velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(2)) - ainf*&
&       machgrid*veldird(2)
      velygrid0 = ainf*machgrid*(-veldir(2))
      velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(3)) - ainf*&
&       machgrid*veldird(3)
      velzgrid0 = ainf*machgrid*(-veldir(3))
    else if (tsbetamode) then
! get the baseline alpha and determine the liftindex
      call getdirangle_d(veldirfreestream, veldirfreestreamd, &
&                  liftdirection, liftindex, alpha, alphad, beta, betad)
!determine the alpha for this time instance
      betaincrement = tsbeta(degreepolbeta, coefpolbeta, degreefourbeta&
&       , omegafourbeta, coscoeffourbeta, sincoeffourbeta, t(1))
      betatsd = betad
      betats = beta + betaincrement
!determine the grid velocity for this alpha
      refdirection(:) = zero
      refdirection(1) = one
      call getdirvector_d(refdirection, alpha, alphad, betats, betatsd, &
&                   veldir, veldird, liftindex)
!do i need to update the lift direction and drag direction as well?
!set the effictive grid velocity for this time interval
      velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(1)) - ainf*&
&       machgrid*veldird(1)
      velxgrid0 = ainf*machgrid*(-veldir(1))
      velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(2)) - ainf*&
&       machgrid*veldird(2)
      velygrid0 = ainf*machgrid*(-veldir(2))
      velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(3)) - ainf*&
&       machgrid*veldird(3)
      velzgrid0 = ainf*machgrid*(-veldir(3))
    else if (tsmachmode) then
!determine the mach number at this time interval
      intervalmach = tsmach(degreepolmach, coefpolmach, degreefourmach, &
&       omegafourmach, coscoeffourmach, sincoeffourmach, t(1))
!set the effective grid velocity
      velxgrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
&       veldirfreestream(1)) - ainf*(intervalmach+machgrid)*&
&       veldirfreestreamd(1)
      velxgrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(1))
      velygrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
&       veldirfreestream(2)) - ainf*(intervalmach+machgrid)*&
&       veldirfreestreamd(2)
      velygrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(2))
      velzgrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
&       veldirfreestream(3)) - ainf*(intervalmach+machgrid)*&
&       veldirfreestreamd(3)
      velzgrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(3))
    else if (tsaltitudemode) then
      call terminate('gridvelocityfinelevel', &
&              'altitude motion not yet implemented...')
    else
      call terminate('gridvelocityfinelevel', &
&              'not a recognized stability motion')
    end if
  end if
  if (blockismoving) then
! determine the situation we are having here.
    if (useoldcoor) then
!
!             the velocities must be determined via a finite           
!             difference formula using the coordinates of the old      
!             levels.                                                  
!
! set the coefficients for the time integrator and store
! the inverse of the physical nondimensional time step,
! divided by 4 and 8, a bit easier.
      call setcoeftimeintegrator()
      oneover4dtd = fourth*timerefd/deltat
      oneover4dt = fourth*timeref/deltat
      oneover8dtd = half*oneover4dtd
      oneover8dt = half*oneover4dt
      sd = 0.0_8
      scd = 0.0_8
!
!             grid velocities of the cell centers, including the       
!             1st level halo cells.                                    
!
! loop over the cells, including the 1st level halo's.
      do k=1,ke
        do j=1,je
          do i=1,ie
! the velocity of the cell center is determined
! by a finite difference formula. first store
! the current coordinate, multiplied by 8 and
! coeftime(0) in sc.
            scd(1) = coeftime(0)*(xd(i-1, j-1, k-1, 1)+xd(i, j-1, k-1, 1&
&             )+xd(i-1, j, k-1, 1)+xd(i, j, k-1, 1)+xd(i-1, j-1, k, 1)+&
&             xd(i, j-1, k, 1)+xd(i-1, j, k, 1)+xd(i, j, k, 1))
            sc(1) = (x(i-1, j-1, k-1, 1)+x(i, j-1, k-1, 1)+x(i-1, j, k-1&
&             , 1)+x(i, j, k-1, 1)+x(i-1, j-1, k, 1)+x(i, j-1, k, 1)+x(i&
&             -1, j, k, 1)+x(i, j, k, 1))*coeftime(0)
            scd(2) = coeftime(0)*(xd(i-1, j-1, k-1, 2)+xd(i, j-1, k-1, 2&
&             )+xd(i-1, j, k-1, 2)+xd(i, j, k-1, 2)+xd(i-1, j-1, k, 2)+&
&             xd(i, j-1, k, 2)+xd(i-1, j, k, 2)+xd(i, j, k, 2))
            sc(2) = (x(i-1, j-1, k-1, 2)+x(i, j-1, k-1, 2)+x(i-1, j, k-1&
&             , 2)+x(i, j, k-1, 2)+x(i-1, j-1, k, 2)+x(i, j-1, k, 2)+x(i&
&             -1, j, k, 2)+x(i, j, k, 2))*coeftime(0)
            scd(3) = coeftime(0)*(xd(i-1, j-1, k-1, 3)+xd(i, j-1, k-1, 3&
&             )+xd(i-1, j, k-1, 3)+xd(i, j, k-1, 3)+xd(i-1, j-1, k, 3)+&
&             xd(i, j-1, k, 3)+xd(i-1, j, k, 3)+xd(i, j, k, 3))
            sc(3) = (x(i-1, j-1, k-1, 3)+x(i, j-1, k-1, 3)+x(i-1, j, k-1&
&             , 3)+x(i, j, k-1, 3)+x(i-1, j-1, k, 3)+x(i, j-1, k, 3)+x(i&
&             -1, j, k, 3)+x(i, j, k, 3))*coeftime(0)
! loop over the older levels to complete the
! finite difference formula.
            do ii=1,noldlevels
              sc(1) = sc(1) + (xold(ii, i-1, j-1, k-1, 1)+xold(ii, i, j-&
&               1, k-1, 1)+xold(ii, i-1, j, k-1, 1)+xold(ii, i, j, k-1, &
&               1)+xold(ii, i-1, j-1, k, 1)+xold(ii, i, j-1, k, 1)+xold(&
&               ii, i-1, j, k, 1)+xold(ii, i, j, k, 1))*coeftime(ii)
              sc(2) = sc(2) + (xold(ii, i-1, j-1, k-1, 2)+xold(ii, i, j-&
&               1, k-1, 2)+xold(ii, i-1, j, k-1, 2)+xold(ii, i, j, k-1, &
&               2)+xold(ii, i-1, j-1, k, 2)+xold(ii, i, j-1, k, 2)+xold(&
&               ii, i-1, j, k, 2)+xold(ii, i, j, k, 2))*coeftime(ii)
              sc(3) = sc(3) + (xold(ii, i-1, j-1, k-1, 3)+xold(ii, i, j-&
&               1, k-1, 3)+xold(ii, i-1, j, k-1, 3)+xold(ii, i, j, k-1, &
&               3)+xold(ii, i-1, j-1, k, 3)+xold(ii, i, j-1, k, 3)+xold(&
&               ii, i-1, j, k, 3)+xold(ii, i, j, k, 3))*coeftime(ii)
            end do
! divide by 8 delta t to obtain the correct
! velocities.
            sd(i, j, k, 1) = scd(1)*oneover8dt + sc(1)*oneover8dtd
            s(i, j, k, 1) = sc(1)*oneover8dt
            sd(i, j, k, 2) = scd(2)*oneover8dt + sc(2)*oneover8dtd
            s(i, j, k, 2) = sc(2)*oneover8dt
            sd(i, j, k, 3) = scd(3)*oneover8dt + sc(3)*oneover8dtd
            s(i, j, k, 3) = sc(3)*oneover8dt
          end do
        end do
      end do
      sfaceid = 0.0_8
      sfacejd = 0.0_8
      sfacekd = 0.0_8
!
!             normal grid velocities of the faces.                     
!
! loop over the three directions.
loopdir:do mm=1,3
! set the upper boundaries depending on the direction.
        select case  (mm) 
        case (1_inttype) 
! normals in i-direction
          iie = ie
          jje = je
          kke = ke
        case (2_inttype) 
! normals in j-direction
          iie = je
          jje = ie
          kke = ke
        case (3_inttype) 
! normals in k-direction
          iie = ke
          jje = ie
          kke = je
        end select
!
!               normal grid velocities in generalized i-direction.     
!               mm == 1: i-direction                                   
!               mm == 2: j-direction                                   
!               mm == 3: k-direction                                   
!
        do i=0,iie
! set the pointers for the coordinates, normals and
! normal velocities for this generalized i-plane.
! this depends on the value of mm.
          select case  (mm) 
          case (1_inttype) 
! normals in i-direction
            xxd => xd(i, :, :, :)
            xx => x(i, :, :, :)
            xxold => xold(:, i, :, :, :)
            ssd => sid(i, :, :, :)
            ss => si(i, :, :, :)
            sfaced => sfaceid(i, :, :)
            sface => sfacei(i, :, :)
          case (2_inttype) 
! normals in j-direction
            xxd => xd(:, i, :, :)
            xx => x(:, i, :, :)
            xxold => xold(:, :, i, :, :)
            ssd => sjd(:, i, :, :)
            ss => sj(:, i, :, :)
            sfaced => sfacejd(:, i, :)
            sface => sfacej(:, i, :)
          case (3_inttype) 
! normals in k-direction
            xxd => xd(:, :, i, :)
            xx => x(:, :, i, :)
            xxold => xold(:, :, :, i, :)
            ssd => skd(:, :, i, :)
            ss => sk(:, :, i, :)
            sfaced => sfacekd(:, :, i)
            sface => sfacek(:, :, i)
          end select
! loop over the k and j-direction of this
! generalized i-face. note that due to the usage of
! the pointers xx and xxold an offset of +1 must be
! used in the coordinate arrays, because x and xold
! originally start at 0 for the i, j and k indices.
          do k=1,kke
            do j=1,jje
! the velocity of the face center is determined
! by a finite difference formula. first store
! the current coordinate, multiplied by 4 and
! coeftime(0) in sc.
              scd(1) = coeftime(0)*(xxd(j+1, k+1, 1)+xxd(j, k+1, 1)+xxd(&
&               j+1, k, 1)+xxd(j, k, 1))
              sc(1) = coeftime(0)*(xx(j+1, k+1, 1)+xx(j, k+1, 1)+xx(j+1&
&               , k, 1)+xx(j, k, 1))
              scd(2) = coeftime(0)*(xxd(j+1, k+1, 2)+xxd(j, k+1, 2)+xxd(&
&               j+1, k, 2)+xxd(j, k, 2))
              sc(2) = coeftime(0)*(xx(j+1, k+1, 2)+xx(j, k+1, 2)+xx(j+1&
&               , k, 2)+xx(j, k, 2))
              scd(3) = coeftime(0)*(xxd(j+1, k+1, 3)+xxd(j, k+1, 3)+xxd(&
&               j+1, k, 3)+xxd(j, k, 3))
              sc(3) = coeftime(0)*(xx(j+1, k+1, 3)+xx(j, k+1, 3)+xx(j+1&
&               , k, 3)+xx(j, k, 3))
! loop over the older levels to complete the
! finite difference.
              do ii=1,noldlevels
                sc(1) = sc(1) + coeftime(ii)*(xxold(ii, j+1, k+1, 1)+&
&                 xxold(ii, j, k+1, 1)+xxold(ii, j+1, k, 1)+xxold(ii, j&
&                 , k, 1))
                sc(2) = sc(2) + coeftime(ii)*(xxold(ii, j+1, k+1, 2)+&
&                 xxold(ii, j, k+1, 2)+xxold(ii, j+1, k, 2)+xxold(ii, j&
&                 , k, 2))
                sc(3) = sc(3) + coeftime(ii)*(xxold(ii, j+1, k+1, 3)+&
&                 xxold(ii, j, k+1, 3)+xxold(ii, j+1, k, 3)+xxold(ii, j&
&                 , k, 3))
              end do
! determine the dot product of sc and the normal
! and divide by 4 deltat to obtain the correct
! value of the normal velocity.
              sfaced(j, k) = scd(1)*ss(j, k, 1) + sc(1)*ssd(j, k, 1) + &
&               scd(2)*ss(j, k, 2) + sc(2)*ssd(j, k, 2) + scd(3)*ss(j, k&
&               , 3) + sc(3)*ssd(j, k, 3)
              sface(j, k) = sc(1)*ss(j, k, 1) + sc(2)*ss(j, k, 2) + sc(3&
&               )*ss(j, k, 3)
              sfaced(j, k) = sfaced(j, k)*oneover4dt + sface(j, k)*&
&               oneover4dtd
              sface(j, k) = sface(j, k)*oneover4dt
            end do
          end do
        end do
      end do loopdir
    else
!
!             the velocities must be determined analytically.          
!
! store the rotation center and determine the
! nondimensional rotation rate of this block. as the
! reference length is 1 timeref == 1/uref and at the end
! the nondimensional velocity is computed.
      j = nbkglobal
      rotcenter = cgnsdoms(j)%rotcenter
      rotrated = cgnsdoms(j)%rotrate*timerefd
      rotrate = timeref*cgnsdoms(j)%rotrate
      velxgridd = velxgrid0d
      velxgrid = velxgrid0
      velygridd = velygrid0d
      velygrid = velygrid0
      velzgridd = velzgrid0d
      velzgrid = velzgrid0
      sd = 0.0_8
      xcd = 0.0_8
      xxcd = 0.0_8
      scd = 0.0_8
!
!             grid velocities of the cell centers, including the       
!             1st level halo cells.                                    
!
! loop over the cells, including the 1st level halo's.
      do k=1,ke
        do j=1,je
          do i=1,ie
! determine the coordinates of the cell center,
! which are stored in xc.
            xcd(1) = eighth*(xd(i-1, j-1, k-1, 1)+xd(i, j-1, k-1, 1)+xd(&
&             i-1, j, k-1, 1)+xd(i, j, k-1, 1)+xd(i-1, j-1, k, 1)+xd(i, &
&             j-1, k, 1)+xd(i-1, j, k, 1)+xd(i, j, k, 1))
            xc(1) = eighth*(x(i-1, j-1, k-1, 1)+x(i, j-1, k-1, 1)+x(i-1&
&             , j, k-1, 1)+x(i, j, k-1, 1)+x(i-1, j-1, k, 1)+x(i, j-1, k&
&             , 1)+x(i-1, j, k, 1)+x(i, j, k, 1))
            xcd(2) = eighth*(xd(i-1, j-1, k-1, 2)+xd(i, j-1, k-1, 2)+xd(&
&             i-1, j, k-1, 2)+xd(i, j, k-1, 2)+xd(i-1, j-1, k, 2)+xd(i, &
&             j-1, k, 2)+xd(i-1, j, k, 2)+xd(i, j, k, 2))
            xc(2) = eighth*(x(i-1, j-1, k-1, 2)+x(i, j-1, k-1, 2)+x(i-1&
&             , j, k-1, 2)+x(i, j, k-1, 2)+x(i-1, j-1, k, 2)+x(i, j-1, k&
&             , 2)+x(i-1, j, k, 2)+x(i, j, k, 2))
            xcd(3) = eighth*(xd(i-1, j-1, k-1, 3)+xd(i, j-1, k-1, 3)+xd(&
&             i-1, j, k-1, 3)+xd(i, j, k-1, 3)+xd(i-1, j-1, k, 3)+xd(i, &
&             j-1, k, 3)+xd(i-1, j, k, 3)+xd(i, j, k, 3))
            xc(3) = eighth*(x(i-1, j-1, k-1, 3)+x(i, j-1, k-1, 3)+x(i-1&
&             , j, k-1, 3)+x(i, j, k-1, 3)+x(i-1, j-1, k, 3)+x(i, j-1, k&
&             , 3)+x(i-1, j, k, 3)+x(i, j, k, 3))
! determine the coordinates relative to the
! center of rotation.
            xxcd(1) = xcd(1)
            xxc(1) = xc(1) - rotcenter(1)
            xxcd(2) = xcd(2)
            xxc(2) = xc(2) - rotcenter(2)
            xxcd(3) = xcd(3)
            xxc(3) = xc(3) - rotcenter(3)
! determine the rotation speed of the cell center,
! which is omega*r.
            scd(1) = rotrated(2)*xxc(3) + rotrate(2)*xxcd(3) - rotrated(&
&             3)*xxc(2) - rotrate(3)*xxcd(2)
            sc(1) = rotrate(2)*xxc(3) - rotrate(3)*xxc(2)
            scd(2) = rotrated(3)*xxc(1) + rotrate(3)*xxcd(1) - rotrated(&
&             1)*xxc(3) - rotrate(1)*xxcd(3)
            sc(2) = rotrate(3)*xxc(1) - rotrate(1)*xxc(3)
            scd(3) = rotrated(1)*xxc(2) + rotrate(1)*xxcd(2) - rotrated(&
&             2)*xxc(1) - rotrate(2)*xxcd(1)
            sc(3) = rotrate(1)*xxc(2) - rotrate(2)*xxc(1)
! determine the coordinates relative to the
! rigid body rotation point.
            xxcd(1) = xcd(1)
            xxc(1) = xc(1) - rotationpoint(1)
            xxcd(2) = xcd(2)
            xxc(2) = xc(2) - rotationpoint(2)
            xxcd(3) = xcd(3)
            xxc(3) = xc(3) - rotationpoint(3)
! determine the total velocity of the cell center.
! this is a combination of rotation speed of this
! block and the entire rigid body rotation.
            sd(i, j, k, 1) = scd(1) + velxgridd + derivrotationmatrixd(1&
&             , 1)*xxc(1) + derivrotationmatrix(1, 1)*xxcd(1) + &
&             derivrotationmatrixd(1, 2)*xxc(2) + derivrotationmatrix(1&
&             , 2)*xxcd(2) + derivrotationmatrixd(1, 3)*xxc(3) + &
&             derivrotationmatrix(1, 3)*xxcd(3)
            s(i, j, k, 1) = sc(1) + velxgrid + derivrotationmatrix(1, 1)&
&             *xxc(1) + derivrotationmatrix(1, 2)*xxc(2) + &
&             derivrotationmatrix(1, 3)*xxc(3)
            sd(i, j, k, 2) = scd(2) + velygridd + derivrotationmatrixd(2&
&             , 1)*xxc(1) + derivrotationmatrix(2, 1)*xxcd(1) + &
&             derivrotationmatrixd(2, 2)*xxc(2) + derivrotationmatrix(2&
&             , 2)*xxcd(2) + derivrotationmatrixd(2, 3)*xxc(3) + &
&             derivrotationmatrix(2, 3)*xxcd(3)
            s(i, j, k, 2) = sc(2) + velygrid + derivrotationmatrix(2, 1)&
&             *xxc(1) + derivrotationmatrix(2, 2)*xxc(2) + &
&             derivrotationmatrix(2, 3)*xxc(3)
            sd(i, j, k, 3) = scd(3) + velzgridd + derivrotationmatrixd(3&
&             , 1)*xxc(1) + derivrotationmatrix(3, 1)*xxcd(1) + &
&             derivrotationmatrixd(3, 2)*xxc(2) + derivrotationmatrix(3&
&             , 2)*xxcd(2) + derivrotationmatrixd(3, 3)*xxc(3) + &
&             derivrotationmatrix(3, 3)*xxcd(3)
            s(i, j, k, 3) = sc(3) + velzgrid + derivrotationmatrix(3, 1)&
&             *xxc(1) + derivrotationmatrix(3, 2)*xxc(2) + &
&             derivrotationmatrix(3, 3)*xxc(3)
          end do
        end do
      end do
      sfaceid = 0.0_8
      sfacejd = 0.0_8
      sfacekd = 0.0_8
!
!             normal grid velocities of the faces.                     
!
! loop over the three directions.
loopdirection:do mm=1,3
! set the upper boundaries depending on the direction.
        select case  (mm) 
        case (1_inttype) 
! normals in i-direction
          iie = ie
          jje = je
          kke = ke
        case (2_inttype) 
! normals in j-direction
          iie = je
          jje = ie
          kke = ke
        case (3_inttype) 
! normals in k-direction
          iie = ke
          jje = ie
          kke = je
        end select
!
!               normal grid velocities in generalized i-direction.     
!               mm == 1: i-direction                                   
!               mm == 2: j-direction                                   
!               mm == 3: k-direction                                   
!
        do i=0,iie
! set the pointers for the coordinates, normals and
! normal velocities for this generalized i-plane.
! this depends on the value of mm.
          select case  (mm) 
          case (1_inttype) 
! normals in i-direction
            xxd => xd(i, :, :, :)
            xx => x(i, :, :, :)
            ssd => sid(i, :, :, :)
            ss => si(i, :, :, :)
            sfaced => sfaceid(i, :, :)
            sface => sfacei(i, :, :)
          case (2_inttype) 
! normals in j-direction
            xxd => xd(:, i, :, :)
            xx => x(:, i, :, :)
            ssd => sjd(:, i, :, :)
            ss => sj(:, i, :, :)
            sfaced => sfacejd(:, i, :)
            sface => sfacej(:, i, :)
          case (3_inttype) 
! normals in k-direction
            xxd => xd(:, :, i, :)
            xx => x(:, :, i, :)
            ssd => skd(:, :, i, :)
            ss => sk(:, :, i, :)
            sfaced => sfacekd(:, :, i)
            sface => sfacek(:, :, i)
          end select
! loop over the k and j-direction of this generalized
! i-face. note that due to the usage of the pointer
! xx an offset of +1 must be used in the coordinate
! array, because x originally starts at 0 for the
! i, j and k indices.
          do k=1,kke
            do j=1,jje
! determine the coordinates of the face center,
! which are stored in xc.
              xcd(1) = fourth*(xxd(j+1, k+1, 1)+xxd(j, k+1, 1)+xxd(j+1, &
&               k, 1)+xxd(j, k, 1))
              xc(1) = fourth*(xx(j+1, k+1, 1)+xx(j, k+1, 1)+xx(j+1, k, 1&
&               )+xx(j, k, 1))
              xcd(2) = fourth*(xxd(j+1, k+1, 2)+xxd(j, k+1, 2)+xxd(j+1, &
&               k, 2)+xxd(j, k, 2))
              xc(2) = fourth*(xx(j+1, k+1, 2)+xx(j, k+1, 2)+xx(j+1, k, 2&
&               )+xx(j, k, 2))
              xcd(3) = fourth*(xxd(j+1, k+1, 3)+xxd(j, k+1, 3)+xxd(j+1, &
&               k, 3)+xxd(j, k, 3))
              xc(3) = fourth*(xx(j+1, k+1, 3)+xx(j, k+1, 3)+xx(j+1, k, 3&
&               )+xx(j, k, 3))
! determine the coordinates relative to the
! center of rotation.
              xxcd(1) = xcd(1)
              xxc(1) = xc(1) - rotcenter(1)
              xxcd(2) = xcd(2)
              xxc(2) = xc(2) - rotcenter(2)
              xxcd(3) = xcd(3)
              xxc(3) = xc(3) - rotcenter(3)
! determine the rotation speed of the face center,
! which is omega*r.
              scd(1) = rotrated(2)*xxc(3) + rotrate(2)*xxcd(3) - &
&               rotrated(3)*xxc(2) - rotrate(3)*xxcd(2)
              sc(1) = rotrate(2)*xxc(3) - rotrate(3)*xxc(2)
              scd(2) = rotrated(3)*xxc(1) + rotrate(3)*xxcd(1) - &
&               rotrated(1)*xxc(3) - rotrate(1)*xxcd(3)
              sc(2) = rotrate(3)*xxc(1) - rotrate(1)*xxc(3)
              scd(3) = rotrated(1)*xxc(2) + rotrate(1)*xxcd(2) - &
&               rotrated(2)*xxc(1) - rotrate(2)*xxcd(1)
              sc(3) = rotrate(1)*xxc(2) - rotrate(2)*xxc(1)
! determine the coordinates relative to the
! rigid body rotation point.
              xxcd(1) = xcd(1)
              xxc(1) = xc(1) - rotationpoint(1)
              xxcd(2) = xcd(2)
              xxc(2) = xc(2) - rotationpoint(2)
              xxcd(3) = xcd(3)
              xxc(3) = xc(3) - rotationpoint(3)
! determine the total velocity of the cell face.
! this is a combination of rotation speed of this
! block and the entire rigid body rotation.
              scd(1) = scd(1) + velxgridd + derivrotationmatrixd(1, 1)*&
&               xxc(1) + derivrotationmatrix(1, 1)*xxcd(1) + &
&               derivrotationmatrixd(1, 2)*xxc(2) + derivrotationmatrix(&
&               1, 2)*xxcd(2) + derivrotationmatrixd(1, 3)*xxc(3) + &
&               derivrotationmatrix(1, 3)*xxcd(3)
              sc(1) = sc(1) + velxgrid + derivrotationmatrix(1, 1)*xxc(1&
&               ) + derivrotationmatrix(1, 2)*xxc(2) + &
&               derivrotationmatrix(1, 3)*xxc(3)
              scd(2) = scd(2) + velygridd + derivrotationmatrixd(2, 1)*&
&               xxc(1) + derivrotationmatrix(2, 1)*xxcd(1) + &
&               derivrotationmatrixd(2, 2)*xxc(2) + derivrotationmatrix(&
&               2, 2)*xxcd(2) + derivrotationmatrixd(2, 3)*xxc(3) + &
&               derivrotationmatrix(2, 3)*xxcd(3)
              sc(2) = sc(2) + velygrid + derivrotationmatrix(2, 1)*xxc(1&
&               ) + derivrotationmatrix(2, 2)*xxc(2) + &
&               derivrotationmatrix(2, 3)*xxc(3)
              scd(3) = scd(3) + velzgridd + derivrotationmatrixd(3, 1)*&
&               xxc(1) + derivrotationmatrix(3, 1)*xxcd(1) + &
&               derivrotationmatrixd(3, 2)*xxc(2) + derivrotationmatrix(&
&               3, 2)*xxcd(2) + derivrotationmatrixd(3, 3)*xxc(3) + &
&               derivrotationmatrix(3, 3)*xxcd(3)
              sc(3) = sc(3) + velzgrid + derivrotationmatrix(3, 1)*xxc(1&
&               ) + derivrotationmatrix(3, 2)*xxc(2) + &
&               derivrotationmatrix(3, 3)*xxc(3)
! store the dot product of grid velocity sc and
! the normal ss in sface.
              sfaced(j, k) = scd(1)*ss(j, k, 1) + sc(1)*ssd(j, k, 1) + &
&               scd(2)*ss(j, k, 2) + sc(2)*ssd(j, k, 2) + scd(3)*ss(j, k&
&               , 3) + sc(3)*ssd(j, k, 3)
              sface(j, k) = sc(1)*ss(j, k, 1) + sc(2)*ss(j, k, 2) + sc(3&
&               )*ss(j, k, 3)
            end do
          end do
        end do
      end do loopdirection
    end if
  else
    sfaceid = 0.0_8
    sfacejd = 0.0_8
    sd = 0.0_8
    sfacekd = 0.0_8
  end if
end subroutine gridvelocitiesfinelevel_block_d
