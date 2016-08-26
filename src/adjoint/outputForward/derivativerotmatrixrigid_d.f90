!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of derivativerotmatrixrigid in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: rotationmatrix
!   with respect to varying inputs: timeref
subroutine derivativerotmatrixrigid_d(rotationmatrix, rotationmatrixd, &
& rotationpoint, t)
!
!       derivativerotmatrixrigid determines the derivative of the      
!       rotation matrix at the given time for the rigid body rotation, 
!       such that the grid velocities can be determined analytically.  
!       also the rotation point of the current time level is           
!       determined. this value can change due to translation of the    
!       entire grid.                                                   
!
  use constants
  use flowvarrefstate
  use inputmotion
  use monitor
  use utils_d, only : rigidrotangle, derivativerigidrotangle, &
& derivativerigidrotangle_d
  implicit none
!
!      subroutine arguments.
!
  real(kind=realtype), intent(in) :: t
  real(kind=realtype), dimension(3), intent(out) :: rotationpoint
  real(kind=realtype), dimension(3, 3), intent(out) :: rotationmatrix
  real(kind=realtype), dimension(3, 3), intent(out) :: rotationmatrixd
!
!      local variables.
!
  integer(kind=inttype) :: i, j
  real(kind=realtype) :: phi, dphix, dphiy, dphiz
  real(kind=realtype) :: dphixd, dphiyd, dphizd
  real(kind=realtype) :: cosx, cosy, cosz, sinx, siny, sinz
  real(kind=realtype), dimension(3, 3) :: dm, m
  real(kind=realtype), dimension(3, 3) :: dmd
  intrinsic sin
  intrinsic cos
! determine the rotation angle around the x-axis for the new
! time level and the corresponding values of the sine and cosine.
  phi = rigidrotangle(degreepolxrot, coefpolxrot, degreefourxrot, &
&   omegafourxrot, coscoeffourxrot, sincoeffourxrot, t)
  sinx = sin(phi)
  cosx = cos(phi)
! idem for the y-axis.
  phi = rigidrotangle(degreepolyrot, coefpolyrot, degreefouryrot, &
&   omegafouryrot, coscoeffouryrot, sincoeffouryrot, t)
  siny = sin(phi)
  cosy = cos(phi)
! idem for the z-axis.
  phi = rigidrotangle(degreepolzrot, coefpolzrot, degreefourzrot, &
&   omegafourzrot, coscoeffourzrot, sincoeffourzrot, t)
  sinz = sin(phi)
  cosz = cos(phi)
! compute the time derivative of the rotation angles around the
! x-axis, y-axis and z-axis.
  dphixd = derivativerigidrotangle_d(degreepolxrot, coefpolxrot, &
&   degreefourxrot, omegafourxrot, coscoeffourxrot, sincoeffourxrot, t, &
&   dphix)
  dphiyd = derivativerigidrotangle_d(degreepolyrot, coefpolyrot, &
&   degreefouryrot, omegafouryrot, coscoeffouryrot, sincoeffouryrot, t, &
&   dphiy)
  dphizd = derivativerigidrotangle_d(degreepolzrot, coefpolzrot, &
&   degreefourzrot, omegafourzrot, coscoeffourzrot, sincoeffourzrot, t, &
&   dphiz)
! compute the time derivative of the rotation matrix applied to
! the coordinates at t == 0.
! part 1. derivative of the z-rotation matrix multiplied by the
! x and y rotation matrix, i.e. dmz * my * mx
  dmd = 0.0_8
  dmd(1, 1) = -(cosy*sinz*dphizd)
  dm(1, 1) = -(cosy*sinz*dphiz)
  dmd(1, 2) = (-(cosx*cosz)-sinx*siny*sinz)*dphizd
  dm(1, 2) = (-(cosx*cosz)-sinx*siny*sinz)*dphiz
  dmd(1, 3) = (sinx*cosz-cosx*siny*sinz)*dphizd
  dm(1, 3) = (sinx*cosz-cosx*siny*sinz)*dphiz
  dmd(2, 1) = cosy*cosz*dphizd
  dm(2, 1) = cosy*cosz*dphiz
  dmd(2, 2) = (sinx*siny*cosz-cosx*sinz)*dphizd
  dm(2, 2) = (sinx*siny*cosz-cosx*sinz)*dphiz
  dmd(2, 3) = (cosx*siny*cosz+sinx*sinz)*dphizd
  dm(2, 3) = (cosx*siny*cosz+sinx*sinz)*dphiz
  dmd(3, 1) = 0.0_8
  dm(3, 1) = zero
  dmd(3, 2) = 0.0_8
  dm(3, 2) = zero
  dmd(3, 3) = 0.0_8
  dm(3, 3) = zero
! part 2: mz * dmy * mx.
  dmd(1, 1) = dmd(1, 1) - siny*cosz*dphiyd
  dm(1, 1) = dm(1, 1) - siny*cosz*dphiy
  dmd(1, 2) = dmd(1, 2) + sinx*cosy*cosz*dphiyd
  dm(1, 2) = dm(1, 2) + sinx*cosy*cosz*dphiy
  dmd(1, 3) = dmd(1, 3) + cosx*cosy*cosz*dphiyd
  dm(1, 3) = dm(1, 3) + cosx*cosy*cosz*dphiy
  dmd(2, 1) = dmd(2, 1) - siny*sinz*dphiyd
  dm(2, 1) = dm(2, 1) - siny*sinz*dphiy
  dmd(2, 2) = dmd(2, 2) + sinx*cosy*sinz*dphiyd
  dm(2, 2) = dm(2, 2) + sinx*cosy*sinz*dphiy
  dmd(2, 3) = dmd(2, 3) + cosx*cosy*sinz*dphiyd
  dm(2, 3) = dm(2, 3) + cosx*cosy*sinz*dphiy
  dmd(3, 1) = dmd(3, 1) - cosy*dphiyd
  dm(3, 1) = dm(3, 1) - cosy*dphiy
  dmd(3, 2) = dmd(3, 2) - sinx*siny*dphiyd
  dm(3, 2) = dm(3, 2) - sinx*siny*dphiy
  dmd(3, 3) = dmd(3, 3) - cosx*siny*dphiyd
  dm(3, 3) = dm(3, 3) - cosx*siny*dphiy
! part 3: mz * my * dmx
  dmd(1, 2) = dmd(1, 2) + (sinx*sinz+cosx*siny*cosz)*dphixd
  dm(1, 2) = dm(1, 2) + (sinx*sinz+cosx*siny*cosz)*dphix
  dmd(1, 3) = dmd(1, 3) + (cosx*sinz-sinx*siny*cosz)*dphixd
  dm(1, 3) = dm(1, 3) + (cosx*sinz-sinx*siny*cosz)*dphix
  dmd(2, 2) = dmd(2, 2) + (cosx*siny*sinz-sinx*cosz)*dphixd
  dm(2, 2) = dm(2, 2) + (cosx*siny*sinz-sinx*cosz)*dphix
  dmd(2, 3) = dmd(2, 3) - (sinx*siny*sinz+cosx*cosz)*dphixd
  dm(2, 3) = dm(2, 3) - (sinx*siny*sinz+cosx*cosz)*dphix
  dmd(3, 2) = dmd(3, 2) + cosx*cosy*dphixd
  dm(3, 2) = dm(3, 2) + cosx*cosy*dphix
  dmd(3, 3) = dmd(3, 3) - sinx*cosy*dphixd
  dm(3, 3) = dm(3, 3) - sinx*cosy*dphix
! determine the rotation matrix at t == t.
  m(1, 1) = cosy*cosz
  m(2, 1) = cosy*sinz
  m(3, 1) = -siny
  m(1, 2) = sinx*siny*cosz - cosx*sinz
  m(2, 2) = sinx*siny*sinz + cosx*cosz
  m(3, 2) = sinx*cosy
  m(1, 3) = cosx*siny*cosz + sinx*sinz
  m(2, 3) = cosx*siny*sinz - sinx*cosz
  m(3, 3) = cosx*cosy
  rotationmatrixd = 0.0_8
! determine the matrix product dm * inverse(m), which will give
! the derivative of the rotation matrix when applied to the
! current coordinates. note that inverse(m) == transpose(m).
  do j=1,3
    do i=1,3
      rotationmatrixd(i, j) = m(j, 1)*dmd(i, 1) + m(j, 2)*dmd(i, 2) + m(&
&       j, 3)*dmd(i, 3)
      rotationmatrix(i, j) = dm(i, 1)*m(j, 1) + dm(i, 2)*m(j, 2) + dm(i&
&       , 3)*m(j, 3)
    end do
  end do
! determine the rotation point at the new time level; it is
! possible that this value changes due to translation of the grid.
!  ainf = sqrt(gammainf*pinf/rhoinf)
!  rotationpoint(1) = lref*rotpoint(1) &
!                    + machgrid(1)*ainf*t/timeref
!  rotationpoint(2) = lref*rotpoint(2) &
!                    + machgrid(2)*ainf*t/timeref
!  rotationpoint(3) = lref*rotpoint(3) &
!                    + machgrid(3)*ainf*t/timeref
  rotationpoint(1) = lref*rotpoint(1)
  rotationpoint(2) = lref*rotpoint(2)
  rotationpoint(3) = lref*rotpoint(3)
end subroutine derivativerotmatrixrigid_d
