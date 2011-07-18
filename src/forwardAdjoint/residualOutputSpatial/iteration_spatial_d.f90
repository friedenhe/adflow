   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          iteration.f90                                   *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 03-13-2003                                      *
   !      * Last modified: 09-20-2007                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   MODULE ITERATION_SPATIAL_D
   USE PRECISION
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * This module contains the iteration parameters mainly used in   *
   !      * solver.                                                        *
   !      *                                                                *
   !      ******************************************************************
   !
   ! groundLevel:  Current ground level of the computation. Needed
   !               to determine what kind of action must be
   !               undertaken. E.G. On the coarse grids no solution
   !               will be written.
   ! currentLevel: MG level at which the compution currently resides.
   ! rkStage:      Current runge kutta stage. Needed to determine
   !               whether or not the artificial dissipation terms
   !               must be computed.
   INTEGER(kind=inttype) :: groundlevel, currentlevel
   INTEGER(kind=inttype) :: rkstage
   ! nStepsCycling: Number of steps in the current cycling strategy
   ! cycling:       The corresponding array defining the multigrid
   !                cycling strategy.
   INTEGER(kind=inttype) :: nstepscycling
   INTEGER(kind=inttype), DIMENSION(:), ALLOCATABLE :: cycling
   ! nMGVar: Number of variables to which the multigrid must be
   !         applied. For the Euler and laminar Navier-Stokes
   !         equations this is the number of flow variables; for
   !         RANS this is either the total number of independent
   !         variables (coupled solver) or the number of flow
   !         variables (segregated solver).
   ! nt1MG:  Starting index for the turbulent variables in MG.
   ! nt2MG:  Ending index for the turbulent variables in MG.
   !         For a segregated solver these values are such
   !         that nothing is done on the turbulent equations.
   INTEGER(kind=inttype) :: nmgvar, nt1mg, nt2mg
   ! restrictEddyVis: Whether or not the eddy viscosity must
   !                  be restricted to the coarser levels.
   ! turbSegregated:  Whether or not the turbulent equations
   !                  are solved segregatedly from the mean
   !                  flow equations.
   ! turbCoupled:     Whether or not the turbulent equations are
   !                  solved in a coupled manner with the mean
   !                  flow equations. The reason why both
   !                  turbCoupled and turbSegregated are used is
   !                  that everything must work for Euler and
   !                  laminar NS as well.
   LOGICAL :: restricteddyvis, turbsegregated, turbcoupled
   ! iterTot: Total number of iterations on the current grid;
   !          a restart is not included in this count.
   INTEGER(kind=inttype) :: itertot
   ! rFil : coefficient to control the fraction of the dissipation
   !        residual of the previous runge-kutta stage.
   REAL(kind=realtype) :: rfil, rfilb
   ! t0Solver: Reference time for the solver.
   REAL(kind=realtype) :: t0solver
   ! converged:             Whether or not the solution has been
   !                        converged.
   ! exchangePressureEarly: Whether or not the pressure must be
   !                        exchanged early, i.e. before the
   !                        boundary conditions are applied.
   !                        This must be done for a correct treatment
   !                        of normal momentum boundary condition,
   !                        but it requires an extra call to the
   !                        halo routines.
   LOGICAL :: converged
   LOGICAL :: exchangepressureearly
   ! standAloneMode:   Whether or not an executable in stand alone
   !                   mode is built.
   ! changing_Grid:    Whether or not the grid changes in time.
   !                   In stand alone mode this only happens when
   !                   moving parts are present. In a
   !                   multi-disciplinary environment more options
   !                   are possible, i.e. deforming meshes.
   ! deforming_Grid:   Whether or not the grid deforms; this can
   !                   only happen for a multi-disciplinary,
   !                   usually aero-elastic problem.
   ! changingOverset:  Whether or not the overset connectivity needs
   !                   to be updated at each time step, due to 
   !                   moving or deforming grids.
   ! PV3Initialized:   Whether or not PV3 has been initialized,
   !                   for use in multidisciplinary problems where
   !                   solver is called multiple times
   LOGICAL :: standalonemode, changing_grid, deforming_grid
   LOGICAL :: changingoverset, pv3initialized=.false.
   ! nOldSolAvail:     Number of available old solutions for
   !                   the time integration.
   ! nOldLevels:       Number of old levels needed in the time
   !                   integration scheme.
   ! coefTime(0:nOld): The coefficients in the time integrator
   !                   for unsteady applications.
   INTEGER(kind=inttype) :: noldsolavail, noldlevels
   REAL(kind=realtype), DIMENSION(:), ALLOCATABLE :: coeftime
   REAL(kind=realtype), DIMENSION(:), ALLOCATABLE :: coeftimed
   ! timeSpectralGridsNotWritten: Whether or not grid files have
   !                              already been written in time
   !                              spectral mode. In this way
   !                              it is avoided that files are
   !                              written multiple times.
   ! oldSolWritten(nOldLevels-1): Logicals to indicate whether
   !                              or not old solution levels
   !                              have been written in
   !                              unsteady mode.
   LOGICAL :: timespectralgridsnotwritten
   LOGICAL, DIMENSION(:), ALLOCATABLE :: oldsolwritten
   END MODULE ITERATION_SPATIAL_D
