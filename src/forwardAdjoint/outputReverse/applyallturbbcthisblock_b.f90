   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of applyallturbbcthisblock in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *w
   !   with respect to varying inputs: *bvtj1 *bvtj2 *bmtk1 *w *bmtk2
   !                *bvtk1 *bvtk2 *bmti1 *bmti2 *bvti1 *bvti2 *bmtj1
   !                *bmtj2
   !   Plus diff mem management of: bvtj1:in bvtj2:in bmtk1:in w:in
   !                bmtk2:in bvtk1:in bvtk2:in bmti1:in bmti2:in bvti1:in
   !                bvti2:in bmtj1:in bmtj2:in
   !      ==================================================================
   SUBROUTINE APPLYALLTURBBCTHISBLOCK_B(secondhalo)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * applyAllTurbBCThisBlock sets the halo values of the            *
   !      * turbulent variables and eddy viscosity for the block the       *
   !      * variables in blockPointers currently point to.                 *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BCTYPES
   USE BLOCKPOINTERS_B
   USE FLOWVARREFSTATE
   USE INPUTPHYSICS
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   LOGICAL, INTENT(IN) :: secondhalo
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: nn, i, j, l, m
   REAL(kind=realtype), DIMENSION(:, :, :, :), POINTER :: bmt
   REAL(kind=realtype), DIMENSION(:, :, :, :), POINTER :: bmtb
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: bvt, ww1, ww2
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: bvtb, ww1b, ww2b
   REAL(kind=realtype) :: tmp
   REAL(kind=realtype) :: tmp0
   REAL(kind=realtype) :: tmp1
   INTEGER :: branch
   INTEGER :: ad_from
   INTEGER :: ad_to
   INTEGER :: ad_from0
   INTEGER :: ad_to0
   INTEGER :: ad_from1
   INTEGER :: ad_to1
   INTEGER :: ad_from2
   INTEGER :: ad_to2
   INTERFACE 
   SUBROUTINE PUSHPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE PUSHPOINTER4
   SUBROUTINE LOOKPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE LOOKPOINTER4
   SUBROUTINE POPPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE POPPOINTER4
   END INTERFACE
      REAL(kind=realtype) :: tmpb
   REAL(kind=realtype) :: tmpb1
   REAL(kind=realtype) :: tmpb0
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Loop over the boundary condition subfaces of this block.
   bocos:DO nn=1,nbocos
   CALL PUSHCONTROL3B(0)
   CALL PUSHPOINTER4(bmtb)
   bmtb => bmti1b
   CALL PUSHPOINTER4(bmt)
   bmt => bmti1
   CALL PUSHPOINTER4(bvtb)
   bvtb => bvti1b
   CALL PUSHPOINTER4(bvt)
   bvt => bvti1
   CALL PUSHPOINTER4(ww1b)
   ww1b => wb(1, 1:, 1:, :)
   CALL PUSHPOINTER4(ww1)
   ww1 => w(1, 1:, 1:, :)
   CALL PUSHPOINTER4(ww2b)
   ww2b => wb(2, 1:, 1:, :)
   CALL PUSHPOINTER4(ww2)
   ww2 => w(2, 1:, 1:, :)
   CALL PUSHCONTROL3B(1)
   ! Loop over the faces and set the state in
   ! the turbulent halo cells.
   IF (wallfunctions) THEN
   ad_from0 = bcdata(nn)%jcbeg
   ! Write an approximate value into the halo cell for
   ! postprocessing (it is not used in computation).
   DO j=ad_from0,bcdata(nn)%jcend
   ad_from = bcdata(nn)%icbeg
   DO i=ad_from,bcdata(nn)%icend
   DO l=nt1,nt2
   tmp = bvt(i, j, l) - bmt(i, j, l, l)*ww2(i, j, l)
   CALL PUSHREAL8(ww1(i, j, l))
   ww1(i, j, l) = tmp
   DO m=nt1,nt2
   IF (m .NE. l .AND. bmt(i, j, l, m) .NE. zero) THEN
   tmp0 = ww2(i, j, l)
   CALL PUSHREAL8(ww1(i, j, l))
   ww1(i, j, l) = tmp0
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   END DO
   END DO
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from0)
   CALL PUSHCONTROL1B(0)
   ELSE
   ad_from2 = bcdata(nn)%jcbeg
   DO j=ad_from2,bcdata(nn)%jcend
   ad_from1 = bcdata(nn)%icbeg
   DO i=ad_from1,bcdata(nn)%icend
   DO l=nt1,nt2
   CALL PUSHREAL8(ww1(i, j, l))
   ww1(i, j, l) = bvt(i, j, l)
   DO m=nt1,nt2
   tmp1 = ww1(i, j, l) - bmt(i, j, l, m)*ww2(i, j, m)
   CALL PUSHREAL8(ww1(i, j, l))
   ww1(i, j, l) = tmp1
   END DO
   END DO
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from1)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from2)
   CALL PUSHCONTROL1B(1)
   END IF
   ! Set the value of the eddy viscosity, depending on the type of
   ! boundary condition. Only if the turbulence model is an eddy
   ! viscosity model of course.
   IF (eddymodel) THEN
   IF (bctype(nn) .EQ. nswalladiabatic .OR. bctype(nn) .EQ. &
   &         nswallisothermal) THEN
   ! Viscous wall boundary condition. Eddy viscosity is
   ! zero at the wall.
   CALL BCEDDYWALL(nn)
   ELSE
   ! Any boundary condition but viscous wall. A homogeneous
   ! Neumann condition is applied to the eddy viscosity.
   CALL BCEDDYNOWALL(nn)
   END IF
   END IF
   ! Extrapolate the turbulent variables in case a second halo
   ! is needed.
   IF (secondhalo) THEN
   CALL PUSHREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, 4)&
   &                  )
   CALL TURB2NDHALO(nn)
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   END DO bocos
   bvtj1b = 0.0_8
   bvtj2b = 0.0_8
   bmtk1b = 0.0_8
   bmtk2b = 0.0_8
   bvtk1b = 0.0_8
   bvtk2b = 0.0_8
   bmti1b = 0.0_8
   bmti2b = 0.0_8
   bvti1b = 0.0_8
   bvti2b = 0.0_8
   bmtj1b = 0.0_8
   bmtj2b = 0.0_8
   DO nn=nbocos,1,-1
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) THEN
   CALL POPREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, 4))
   CALL TURB2NDHALO_B(nn)
   END IF
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   CALL POPINTEGER4(ad_from0)
   CALL POPINTEGER4(ad_to0)
   DO j=ad_to0,ad_from0,-1
   CALL POPINTEGER4(ad_from)
   CALL POPINTEGER4(ad_to)
   DO i=ad_to,ad_from,-1
   DO l=nt2,nt1,-1
   DO m=nt2,nt1,-1
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) THEN
   CALL POPREAL8(ww1(i, j, l))
   tmpb0 = ww1b(i, j, l)
   ww1b(i, j, l) = 0.0_8
   ww2b(i, j, l) = ww2b(i, j, l) + tmpb0
   END IF
   END DO
   CALL POPREAL8(ww1(i, j, l))
   tmpb = ww1b(i, j, l)
   ww1b(i, j, l) = 0.0_8
   bvtb(i, j, l) = bvtb(i, j, l) + tmpb
   bmtb(i, j, l, l) = bmtb(i, j, l, l) - ww2(i, j, l)*tmpb
   ww2b(i, j, l) = ww2b(i, j, l) - bmt(i, j, l, l)*tmpb
   END DO
   END DO
   END DO
   ELSE
   CALL POPINTEGER4(ad_from2)
   CALL POPINTEGER4(ad_to2)
   DO j=ad_to2,ad_from2,-1
   CALL POPINTEGER4(ad_from1)
   CALL POPINTEGER4(ad_to1)
   DO i=ad_to1,ad_from1,-1
   DO l=nt2,nt1,-1
   DO m=nt2,nt1,-1
   CALL POPREAL8(ww1(i, j, l))
   tmpb1 = ww1b(i, j, l)
   ww1b(i, j, l) = tmpb1
   bmtb(i, j, l, m) = bmtb(i, j, l, m) - ww2(i, j, m)*tmpb1
   ww2b(i, j, m) = ww2b(i, j, m) - bmt(i, j, l, m)*tmpb1
   END DO
   CALL POPREAL8(ww1(i, j, l))
   bvtb(i, j, l) = bvtb(i, j, l) + ww1b(i, j, l)
   ww1b(i, j, l) = 0.0_8
   END DO
   END DO
   END DO
   END IF
   CALL POPCONTROL3B(branch)
   IF (branch .LT. 3) THEN
   IF (branch .NE. 0) THEN
   IF (branch .EQ. 1) THEN
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvti1b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmti1b => bmtb
   CALL POPPOINTER4(bmtb)
   ELSE
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvti2b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmti2b => bmtb
   CALL POPPOINTER4(bmtb)
   END IF
   END IF
   ELSE IF (branch .LT. 5) THEN
   IF (branch .EQ. 3) THEN
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvtj1b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmtj1b => bmtb
   CALL POPPOINTER4(bmtb)
   ELSE
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvtj2b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmtj2b => bmtb
   CALL POPPOINTER4(bmtb)
   END IF
   ELSE IF (branch .EQ. 5) THEN
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvtk1b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmtk1b => bmtb
   CALL POPPOINTER4(bmtb)
   ELSE
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(ww2b)
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww1b)
   CALL POPPOINTER4(bvt)
   bvtk2b => bvtb
   CALL POPPOINTER4(bvtb)
   CALL POPPOINTER4(bmt)
   bmtk2b => bmtb
   CALL POPPOINTER4(bmtb)
   END IF
   END DO
   END SUBROUTINE APPLYALLTURBBCTHISBLOCK_B