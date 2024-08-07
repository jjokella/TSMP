!+ Source module for the setup of the LM
!------------------------------------------------------------------------------

MODULE src_setup

!------------------------------------------------------------------------------
!
! Description:
!   This module performs the setup of the model. Special tasks are
!   - the initialization of the environment (sequential or parallel);
!     (if running in parallel mode: MPI-Initialization)
!   - initialization of the timing
!   - reading (and distributing) the NAMELIST input
!   - if running in parallel mode: domain decomposition
!     (in sequential mode only further variables are set)
!   - allocation of space for the meteorological fields
!   - calculating mathematical, physical and other constants
!   - writing a coverpage
!   - if wanted: generation of artificial data
!
! Current Code Owner: DWD, Ulrich Schaettler
!  phone:  +49  69  8062 2739
!  fax:    +49  69  8062 3721
!  email:  ulrich.schaettler@dwd.de
!
! History:
! Version    Date       Name
! ---------- ---------- ----
! 1.1        1998/03/11 Ulrich Schaettler
!  Initial release
! 1.2        1998/03/30 Ulrich Schaettler
!  New variables and subroutine input_inictl for digital filtering
! 1.3        1998/04/15 Guenther Doms
!  New tendency arrays for convection
! 1.4        1998/05/22 Guenther Doms
!  Adaptions for the two time-level integration scheme.
! 1.5        1998/06/29 Guenther Dom
!  Use of new variables for the Rayleigh damping layer formulation 
! 1.7        1998/07/16 Guenther Doms
!  Removal of the global field 'rrssk'.
! 1.8        1998/08/03 Ulrich Schaettler
!  Correction of ANSI violations.
! 1.9        1998/09/16 Guenther Doms
!  Use of parameters 'nincmxt' and 'nincmxu' (replacing 'nincmxn') from
!  data module 'data_runcontrol.f90'.
! 1.10       1998/09/29 Ulrich Schaettler
!  Introduced new control variables for NAMELIST input (preparations
!  for nudging, semi-implicit scheme and llm).
! 1.11       1998/10/13 Christoph Schraff
!  Additional variables for selecting analysis fields.
! 1.17       1998/11/17 Ulrich Schaettler
!  Rew control variables for NAMELIST input (ready files).
! 1.19       1998/12/11 Christoph Schraff
!  Additional variables for selecting the verification period.
! 1.20       1999/01/07 Guenther Doms
!  Renaming of some global variables
! 1.24       1999/03/01 Guenther Doms
!  Inclusion of the new prognostic 3-D array 'qi' (cloud ice).
! 1.29       1999/05/11 Ulrich Schaettler
!  Adapted interfaces to utility-modules and prepared use of MPE_IO
! 1.30       1999/06/24 Matthias Raschendorfer
!  Use additional parameters for module data_runcontrol:
!  These are: ntke, itype_(wcld, tran, turb, synd), imode_(tran, turb), 
!  icldm_(rad, tran, turb), lturhor, lexpcor, lnonloc, lcpfluc, lgpspec,
!  lam_h, lam_m, pat_len.
!  Use additional constants: lhocp,rcpv, rcpl, con_h, con_m
!  Use additional fields: tke, tketens, rcld, tfh, tfm,
!  h_can, d_pat, c_big, c_sml, r_air, t_e, qv_e.
!  Use additional parameters for module data_runcontrol: lcape, lctke, lbats
!  Use additional fields: mflx_con, cape_con, tke_con, qcvg_con
! 1.31       1999/07/01 Christoph Schraff
!  Introduction of on/off switch for verification also of passive reports.
! 1.32       1999/08/24 Guenther Doms
!  New control variable 'l2dim' for 2-D model runs imported.
! 1.33       1999/10/14 Matthias Raschendorfer
!  Use additional fields 'idiv_hum' and 'aevap_s' (R.Hess)
!  Introduction of 2 LOGICAL namelist-parameter controlling the physics
!  (ltmpcor, lprfcor).
!  Removal of a LOGICAL namelist-parameter (lbats).
!  Introduction of 2 INTEGER-namelist-parameters controlling the evaporation:
!  (itype_trvg, itype_evsl).
!  Introduction of a REAL-namelist-parameter (crsmin) to control transpiration.
!  Introduction of 6 REAL-namelist-parameter controlling the turbulence:
!  (tur_len, a_heat, d_heat, a_mom, d_mom, c_diff, rat_lam, rat_can, 
!   c_lnd, c_see).
!  Use additional field: sai.
! 1.34       1999/12/10 Ulrich Schaettler
!  Put allocation and deallocation of memory to new module src_allocation;
!  put setup_vartab to organize_data; use new timing routines
! 1.36       2000/02/24 Christoph Schraff
!   Additional namelist parameter 'mruntyp' defining increments written to VOF.
!   Additional namelist parameter 'lcd244' defining ACAR aircrafts.
! 1.39       2000/05/03 Ulrich Schaettler
!  Changed some variable names and splitted Namelist Input. Only the groups
!  lmgrid and runctl are still read here. 
!  The routine constants has been splitted into several parts.
!  All module subroutines are included now in src_setup.f90.
! 2.8        2001/07/06 Ulrich Schaettler
!  Introduced new NAMELIST variable lreorder (see also environment.f90)
! 2.17       2002/05/08 Ulrich Schaettler
!  Modifications to perform I/O-communications in irealgrib-format;
!  Changed definition for rhde (for computing the snow covered ground)
! 2.18       2002/07/16 Reinhold Schrodin
!  Eliminated variable rhde
! 3.5        2003/09/02 Ulrich Schaettler
!  Read new Namelist parameters for RUNCTL;
!  compute fields phi_tot, rla_tot for avoiding communications in the radiation
! 3.6        2003/12/11 Ulrich Schaettler
!  Modifications for checking the IOSTAT-value when reading the NAMELISTs
! 3.7        2004/02/18 Ulrich Schaettler
!  Read new Namelist parameters for computing synthetic satellite images
!  Replaced phi(rlat), rla(rlon), cphi(crlat), acphir(acrlat), tgphi(tgrlat)
! 3.8        2004/03/23 Jochen Foerstner
!  Corrections for runs with l2dim and the Runge-Kutta scheme
! 3.13       2004/12/03 Jochen Foerstnerr
!  Adaptations for 2 timelevel scheme
! 3.14       2005/01/25 Jochen Foerstner
!  Eliminated irunge_kutta, which is not set in this stage of the LM
! 3.16       2005/07/22 Ulrich Schaettler
!  Added dielectric constants for water and ice; density for ice
! 3.18       2006/03/03 Ulrich Schaettler
!  Subroutine "constants" moved to public for use by the Single Column Model
!  Introduced switch lyear_360 for use of a climatological year with 360 days
!  Determination of nstart in case of Restarts corrected
! 3.21       2006/12/04 Burkhardt Rockel, Christoph Gebhardt
!  Introduced new Namelist parameter polgam
!  Introduced new Namelist parameter leps for ensemble prediction mode
!  Introduced new Namelist group TUNING
!  Initialization of 3D mask array for horizontal diffusion in constant_fields
!  Preset field fccos if running with deep atmosphere
! 3.22       2007/01/24 Jochen Foerstner
!  For explicit lateral boundary conditions: replaced the COS function by EXP
! V3_23        2007/03/30 Ulrich Schaettler, M. Raschendorfer, J. Foerstner
!  Eliminated nstart as Namelist variables; Only allow full hours for hstart
!  Introduced Namelist variables idbg_level, ldebug_xxx, ldump_ascii
!  Some technical cleanups
!  Changing 'input_tuning' to a PUBLIC routine.    (Matthias Raschendorfer)
!  Moving 'clc_diag', 'q_crit' and 'akt' to MODULE data_turbulence.
!  Using initializations in MODULEs data_(turbulence, soil) as default values.
!  Initialization of field rmyq (for lateral boundary relaxation of qr,qs,qg)
!     (by Jochen Foerstner)
! V3_24        2007/04/26 Ulrich Schaettler
!  Changed defaults of namelist variables lreproduce, lreorder, ltime_barrier
!  Added security checks for the namelist variables in /TUNING/
!  Eliminated nincmxu, nincmxt and introduced control as for other increments
! V4_1         2007/12/04 Ulrich Schaettler
!  Fixed the computation of lnorth, lsouth, least, lwest in SR constant_fields
!  to get reproducible results for lexpl_lbc, itype_lbcqx=2
! V4_2         2007/12/05 Hans-Juergen Panitz
!  Wrong initialization of hlastmxt corrected in case of restart
! V4_4         2008/07/16 Ulrich Schaettler
!  Eliminated ltime_mean, ltime_proc; replaced by itype_timing
!  Changed NL parameter lyear_360 to itype_calendar, to have several options
!  Bug Fix: Exchange of indices for setting up horizontal diffusion mask
!    to get reproducible results (by Oliver Fuhrer)
!  Added NL variables gkdrag and gkwake for the sub-grid scale orography scheme
!  in /TUNING/ (Jan-Peter Schulz)
! V4_5         2008/09/10 Ulrich Schaettler, Guenther Zaengl
!  Add namelist parameters entr_sc, mu_rain, cloud_num in TUNING (US)
!  Add namelist parameter lradlbc to use lateral radiative boundary conditions (GZ)
! V4_8         2009/02/16 Ulrich Schaettler
!  Transferred NL variable lartif_data (formerly lgen) from organize_data
!  Moved NL variables lcori, lmetr, lradlbc to organize_dynamics
!  New NL variable for end of (total) simulation ydate_end
!  New NL variable linit_fields for (extra) initialization of local memory
!  Use global_values only, if num_compute greater 1 (Oliver Fuhrer)
! V4_9         2009/07/16 Ulrich Schaettler, Hans-Juergen Panitz
!  Input of new NL switches l_cosmo_art, ldebug_art, l_pollen
!  Add ltime=.FALSE., if itype_timing is not in the valid range
!  Change output format (YUSPEFIC) of cloud_num and cloud_num_d
! V4_10        2009/09/11 Matthias Raschendorfer
! Introduction of the factor a_hshr for the length scale of a separate horizontal
!  shear mode and the factor a_stab for the stability correction of turbulent length scale.
! V4_12        2010/05/11 Ulrich Schaettler, Oli Fuhrer
!  Renamed t0 to t0_melt because of conflicting names
!  Eliminated lhdiff_mask; compute hd_mask in any case
! V4_13        2010/05/11 Michael Gertz
!  Adaptions to SVN
! V4_14        2010/06/14 Ulrich Schaettler
!  New Namelist variable v0snow in /TUNING/ for microphysics
! V4_15        2010/11/19 Ulrich Schaettler, Oliver Fuhrer
!  Distribute value of hstop to all tasks
!  Reduced maximal value of securi to 0.5 because of possible numerical
!  instabilities otherwise (OF)
! V4_17        2011/02/24 Ulrich Blahak
!  Eliminated lperi and my_peri_neigh, added lperi_x/lperi_y
!  Added numerous modifications for lperi_x/lperi_y
!  Increased ibuflen from 1000 to 2000 for very long namelists
!  Allocate sendbuf for exchg_boundaries also in case of num_compute == 1
!    because exchg_boundaries is now called also for 1-proc runs
!    (it is only allocated with dummy length 1 to avoid compile time error message)
!  Set a dummy ydate_ini for artificial data runs if the user does not
!    provide it via namelist parameter ydate_ini
!  Bugfix: izerrstat > 0 from namelist RUNCTL did not lead to model_abort, because
!    izerrstat was re-initialized with 0 in input_tuning() 
!    after input_runctl() before catching izerrstat > 0
!     --> introduced izerrstatv(3) for independent error checking of
!    the namelists.
! V4_18        2011/05/26 Ulrich Schaettler
!  Introduced conditional compilation for Nudging and synthetic satellite images
!  Introduced new Tuning Namelist variable thick_sc
! V4_20        2011/08/31 Matthias Raschendorfer
!  Introduction of ifndefs for SCLM
!  Introduction of p0ref and presetting of kcm
!  tgrlat needs 2 dimensions for v-point dependence (US)
!  Implemented interface to OASIS coupler using conditional compilation with -DCOUP_OAS
!   (by CLM Community)
! V4_21        2011/12/06 Axel Seifert
!  Introduced rain_n0_factor in TUNING Namelist group
! V4_23        2012/05/10 Ulrich Schaettler, CLM
!  Replaced calls to SR difmin, difmin_360 by call to new SR diff_minutes
!  Add support for climatological year with 365 days
!   the usage of a 365 days year is defined by type_calendar=2
!   itype_calendar is an already existing Namelist parameterof Group RUNCTL (CLM)
!  Change of format of internal READ from I2 to I4 when defining the
!   initial and end years of a simulation for calculating the final
!   timestep index nfinalstop (CLM)
! V4_24        2012/06/22 Hendrik Reich
!  Changed formats of the date variables ydate_[ini,bd,end] (now 14 instead of 10 digits)
!  Check whether 10 or 14 digits are given on input and set internal logical
!    flag lmmss accordingly
! V4_25        2012/09/28 Ulrich Schaettler, Carlos Osuna
!  Changed output format for YUSPECIF to proper print all variables;
!  Corrected some print outs
!  Introduce namelist variables to control netcdf asyn I/O behaviour (CO)
! V4_26        2012/12/06 Hans-Juergen Panitz
!  Set the correct timestep counter so that the correct date string is calculated  
!   for restarts at full hours in case of 14 digits for the date string
!   (which means: eliminate ntstepstart) (HJP)
! V4_27        2013/03/19 Michael Baldauf, Ulrich Blahak, Astrid Kerkweg
!  Moved SR set_constants from src_setup to data_constants, so that it can
!   also be used easily by other programs (MB)
!  Added consistency check for l2dim and lperi_y (UB)
!  Introduced MESSy interface (AK)
! V4_28        2013/07/12 Ulrich Schaettler
!  Compute new global variables endlon_tot, endlat_tot
!  Introduced new NL variable lroutine for specifying operational runs
!  Enlarged interface to init_environment to initialize MPI type for special
!   grib_api integer
! V4_29        2013/10/04 Astrid Kerkweg, Ulrich Schaettler
!  Check that MESSY is not used with data assimilation or DFI
! V5_1         2014-11-28 Ulrich Schaettler, Ulrich Blahak, Matthias Raschendorfer
!                         Oliver Fuhrer, Michael Baldauf, Anne Roches, Xavier Lapillonne
!                         Lucio Torrisi
!  Introduced namelist parameters for reference atmosphere (necessary with GRIB2 input)
!  Eliminated checks for input of rotated pole coordinates (because they are not 
!   really coordinates but rotation angles) (US)
!  Changed the format of some YUSPECIF entries for the CLM namelist tool. (UB)
!  Implemented F2003 IOMSG-mechanism for better namelist error messages. (UB)
!  Modification of classification into public and private subroutines in case
!   of a SC-compilation (using ifdef SCLM). (MR)
!  New namelist switch luse_radarfwo for switching on the radar forward operator. (UB)
!  Replaced ireals by wp (working precision) (OF)
!  Changes in lateral Davis-relaxation:
!  - Option lexpl_lbc=.FALSE. removed
!  - relaxation coefficient is always =1 at the boundary.
!  - now crltau_inv /= 1 can be used; especially, the Davis-relaxation can be switched
!    off by crltau_inv=0.
!  - simplifications in the calculation of relaxation coefficient
!      (mathematically equivalent, but not bit-identical results)
!  New namelist switch ltraj to activate Online Trajectory Module (AR)
!  Implemented block data structure: Reading namelist variable nproma, nblock;
!    Initializing index-arrays for copying from/to blocked fields
!  New namelist switch 'lsppt' for stochastic perturbation of physics tendencies
!    (SPPT) added to namelist 'runctl' (LT)
!
! Code Description:
! Language: Fortran 90.
! Software Standards: "European Standards for Writing and
! Documenting Exchangeable Fortran 90 Code".
!==============================================================================
!
! Declarations:
!
! Modules used:

USE data_parameters, ONLY :   &
    wp,        & ! KIND-type parameter for real variables
    sp,        & ! KIND-type parameter for real variables (single precision)
    dp,        & ! KIND-type parameter for real variables (double precision)
    iintegers, & ! KIND-type parameter for standard integer variables
    intgribf,  & ! KIND-type parameter for fortran files in the grib library
    int_ga       ! integer precision for grib_api: length of message in bytes

!------------------------------------------------------------------------------

USE data_modelconfig, ONLY :   &

! 2. horizontal and vertical sizes of the fields and related variables
! --------------------------------------------------------------------

    ie_tot,       & ! number of grid points in zonal direction
    je_tot,       & ! number of grid points in meridional direction
    ke_tot,       & ! number of grid points in vertical direction
    ie,           & ! number of grid points in zonal direction
    je,           & ! number of grid points in meridional direction
    ke,           & ! number of grid points in vertical direction
    ke1,          & ! KE+1
    kcm,          & ! index of the uppermost canopy level
    ieje,         & ! IE*JE
    iejeke,       & ! IE*JE*KE
    ieke,         & ! IE*KE
    ie_max,       & ! Max. of ie on all processors
    je_max,       & ! Max. of je on all processors

! 3. start- and end-indices for the computations in the horizontal layers
! -----------------------------------------------------------------------
!    These variables give the start- and the end-indices of the 
!    forecast for the prognostic variables in a horizontal layer.
!    Note, that the indices for the wind-speeds u and v differ from 
!    the other ones because of the use of the staggered Arakawa-B-grid.
!    
!   zonal direction
    istart,       & ! start index for the forecast of w, t, qv, qc and pp
    iend,         & ! end index for the forecast of w, t, qv, qc and pp
    istartu,      & ! start index for the forecast of u
    iendu,        & ! end index for the forecast of u
    istartv,      & ! start index for the forecast of v
    iendv,        & ! end index for the forecast of v
    istartpar,    & ! start index for computations in the parallel program
    iendpar,      & ! end index for computations in the parallel program

!   meridional direction
    jstart,       & ! start index for the forecast of w, t, qv, qc and pp
    jend,         & ! end index for the forecast of w, t, qv, qc and pp
    jstartu,      & ! start index for the forecast of u
    jendu,        & ! end index for the forecast of u
    jstartv,      & ! start index for the forecast of v
    jendv,        & ! end index for the forecast of v
    jstartpar,    & ! start index for computations in the parallel program
    jendpar         ! end index for computations in the parallel program

USE data_modelconfig, ONLY :   &

! 4. constants for the horizontal rotated grid and related variables
! ------------------------------------------------------------------

    pollon,       & ! longitude of the rotated north pole (in degrees, E>0)
    pollat,       & ! latitude of the rotated north pole (in degrees, N>0)
    polgam,       & ! angle between the north poles of the systems
    dlon,         & ! grid point distance in zonal direction (in degrees)
    dlat,         & ! grid point distance in meridional direction (in degrees)
    startlon_tot, & ! transformed longitude of the lower left grid point
                    ! of the total domain (in degrees, E>0)
    startlat_tot, & ! transformed latitude of the lower left grid point
                    ! of the total domain (in degrees, N>0)
    endlon_tot,   & ! transformed longitude of the upper right grid point
                    ! of the total domain (in degrees, E>0)
    endlat_tot,   & ! transformed latitude of the upper right grid point
                    ! of the total domain (in degrees, N>0)
    startlon,     & ! transformed longitude of the lower left grid point
                    ! of this subdomain (in degrees, E>0)
    startlat,     & ! transformed latitude of the lower left grid point
                    ! of this subdomain (in degrees, N>0)
    eddlon,       & ! 1 / dlon
    eddlat,       & ! 1 / dlat
    edadlat,      & ! 1 / (radius of the earth * dlat)
    dlonddlat,    & ! dlon / dlat
    dlatddlon,    & ! dlat / dlon
    degrad,       & ! factor for transforming degree to rad
    raddeg,       & ! factor for transforming rad to degree

! 5. variables for the time discretization and related variables
! --------------------------------------------------------------

    dt              ! long time-step

! end of data_modelconfig

!------------------------------------------------------------------------------

USE data_constants  , ONLY :   &
    set_constants, &
    pi,            & ! circle constant
    qi0,           & ! cloud ice threshold for autoconversion
    qc0,           & ! cloud water threshold for autoconversion
    r_earth,       & ! mean radius of the earth (m)
    day_len          ! mean length of the day (s)

! end of data_constants

!------------------------------------------------------------------------------

USE data_fields, ONLY :   &
    rlat     ,    & ! geographical latitude                         ( rad )
    rlon     ,    & ! geographical longitude                        ( rad )
    rlattot  ,    & ! geographical latitude                         ( rad )
    rlontot  ,    & ! geographical longitude                        ( rad )
    fc       ,    & ! coriolis-parameter                            ( 1/s )
    fccos    ,    & ! coriolis-parameter mit cosinus                ( 1/s )
    rmy      ,    & ! Davis-parameter for relaxation (mass, qv, qc)    --
    rmyq     ,    & ! Davis-parameter for relaxation (qr, qs, qg)      --
    hd_mask  ,    & ! 3D-domain mask for horizontal diffusion * dcoeff --
    least_lbdz,   & ! mask for eastern  lateral boundary zone
    lwest_lbdz,   & ! mask for western  lateral boundary zone
    lnorth_lbdz,  & ! mask for northern lateral boundary zone
    lsouth_lbdz,  & ! mask for southern lateral boundary zone
    crlat    ,    & ! cosine of transformed latitude
    acrlat   ,    & ! 1 / ( crlat * radius of the earth )           ( 1/m )
    tgrlat          ! tangens of transformed latitude                 --

!------------------------------------------------------------------------------

USE data_runcontrol , ONLY :   &
    nstart,       & ! first time step of the forecast
    nstop,        & ! last time step of the forecast
    nfinalstop,   & ! last time step of the total forecast
                    ! (necessary, if simulation is splitted into periods)
    hstart,       & ! start of the forecast in full hours
    hstop,        & ! end of the forecast in hours
    ntstep,       & ! actual time step
                    ! indices for permutation of three time levels
    nold,         & ! corresponds to ntstep - 1
    nnow,         & ! corresponds to ntstep
    nnew,         & ! corresponds to ntstep + 1
    ntke,         & ! TKE-timestep corresponds to ntstep
    leps,         & ! if .TRUE., running in ensemble mode (EPS)
    lphys,        & ! forecast with physical parametrizations
    lsppt,        & ! switch, if .true., perturb the physics tend.
    nproma,       & ! block size for physical parameterizations
    nlastproma,   & ! size of last block
    nblock,       & ! number of blocks
    ldiagnos,     & ! forecast with diagnostic computations
    luseobs,      & ! on - off switch for using observational data for:
                    ! - nudging (of conventional data)
                    ! - latent heat nudging (not implemented yet)
                    ! - 2-dim. analyses (2m-Temperature, 2m-Humidity, precipit.)
                    ! - verification of model data against observations
    l_cosmo_art,  & ! if .TRUE., run the COSMO_ART
    l_pollen,     & ! if .TRUE., run the Pollen component
    ltraj,        & ! if .TRUE., compute the trajectories
    lroutine,     & ! if .TRUE., run an operational forecast
    llm,          & ! if .TRUE., running with a lowered upper boundary
    crltau_inv,   & ! factor for relaxation time 1/tau_r = crltau_inv * 1/dt
    rlwidth,      & ! width of relaxation layer
    lcori_deep,   & ! if =.TRUE.: take cos(phi) coriolis terms into account
    lreproduce,   & ! the results are reproducible in parallel mode
    idbg_level,   & ! to control the verbosity of debug output
    ldebug_dyn,   & ! if .TRUE., debug output for dynamics
    ldebug_gsp,   & ! if .TRUE., debug output for grid scale precipitation
    ldebug_rad,   & ! if .TRUE., debug output for radiation
    ldebug_tur,   & ! if .TRUE., debug output for turbulence
    ldebug_con,   & ! if .TRUE., debug output for convection
    ldebug_soi,   & ! if .TRUE., debug output for soil model
    ldebug_io ,   & ! if .TRUE., debug output for I/O
    ldebug_mpe,   & ! if .TRUE., debug output for mpe_io
    ldebug_dia,   & ! if .TRUE., debug output for diagnostics
    ldebug_art,   & ! if .TRUE., debug output for COSMO_ART
    ldebug_ass,   & ! if .TRUE., debug output for assimilation
    ldebug_lhn,   & ! if .TRUE., debug output for latent heat nudging
    lprintdeb_all   ! .TRUE.:  all tasks print debug output

                    ! .FALSE.: only task 0 prints debug output
USE data_runcontrol , ONLY :   &
    ldump_ascii,  & ! for flushing (close and re-open) the ASCII files
    lclock,       & ! system clock is present
    ltime,        & ! detailed timings of the program are given
    itype_timing, & ! determines, how to handle the timing
    linit_fields, & ! to initialize also local variables with a default value
    lartif_data,  & ! forecast with self-defined artificial data
    lperi_x,      & ! lartif_data=.TRUE.:  periodic boundary conditions
                    !            =.FALSE.: with Davies conditions
    lperi_y,      & ! lartif_data=.TRUE.:  periodic boundary conditions
                    !            =.FALSE.: with Davies conditions
    l2dim,        & ! lartif_data=.TRUE.:  2dimensional model version
                    !            =.FALSE.: full 3dimensional version
    lcori,        & ! lartif_data=.TRUE.:  with Coriolis force
                    !            =.FALSE.: or without Coriolis force
    lmetr,        & ! lartif_data=.TRUE.:  with metric terms
                    !            =.FALSE.: or without metric terms
    ldfi,         & ! Logical switch for initialization by digital filtering
    luse_rttov,   & ! if rttov-library is used
    luse_radarfwo,& ! if .TRUE., switch on the radar forward operator
    hlastmxu,     & ! last hour when vbmax was "nullified"
    hnextmxu,     & ! next hour when vbmax will be "nullified"
    hincmxu,      & ! increment that can be specified via Namelist
    hlastmxt,     & ! last hour when tmin, tmax were "nullified"
    hnextmxt,     & ! next hour when tmin, tmax will be "nullified"
    hincmxt,      & ! increment that can be specified via Namelist
    nlastmxu,     & ! last step when vbmax was "nullified"
    nnextmxu,     & ! next step when vbmax will be "nullified"
    nlastmxt,     & ! last step when tmin, tmax were "nullified"
    nnextmxt,     & ! next step when tmin, tmax will be "nullified"
    nudebug,      & ! unit number for file YUDEBUG
    nuspecif,     & ! unit number for file YUSPECIF
    yudebug,      & ! file name
    yuspecif,     & ! file name
    itype_calendar,&! for specifying the calendar used
    yakdat1,      & ! actual date (ydate_ini+ntstep/dt)
                    ! ddmmyyhhmmss (day, month, year, hour, min, sec)
    yakdat2         ! actual date (ydate_ini+ntstep/dt) 
                    ! wd dd.mm.yy (weekday, day, month, year)
! end of data_runcontrol 

!------------------------------------------------------------------------------

USE data_parallel,      ONLY :  &
    ldatatypes,      & ! if .TRUE.: use MPI-Datatypes for some communications
    ltime_barrier,   & ! if .TRUE.: use additional barriers for determining the
                       ! load-imbalance
    nprocx,          & ! number of processors in x-direction
    nprocy,          & ! number of processors in y-direction
    nprocio,         & ! number of extra processors for doing asynchronous IO
    nc_asyn_io,      & ! number of asynchronous I/O PEs (netcdf)
    num_asynio_comm, & ! number of asynchronous I/O communicators (netcdf)
    num_iope_percomm,& ! number of asynchronous I/O PE per communicator (netcdf)
    nproc,           & ! total number of processors: nprocx * nprocy
    num_compute,     & ! number of compute PEs
    nboundlines,     & ! number of boundary lines of the domain for which
                       ! no forecast is computed = overlapping boundary
                       ! lines of the subdomains
    ncomm_type,      & ! type of communication
    my_world_id,     & ! rank of this subdomain in the global communicator
    my_cart_id,      & ! rank of this subdomain in the cartesian communicator
    my_cart_pos,     & ! position of this subdomain in the cartesian grid
                       ! in x- and y-direction
    my_cart_neigh,   & ! neighbors of this subdomain in the cartesian grid
    isubpos,         & ! positions of the subdomains in the total domain. Given
                       ! are the i- and the j-indices of the lower left and the
                       ! upper right grid point in the order
                       !                  i_ll, j_ll, i_ur, j_ur.
                       ! Only the interior of the domains are considered, not
                       ! the boundary lines.
    igroup_world,    & ! group that belongs to MPI_COMM_WORLD, i.e. all
                       ! processors
    icomm_world,     & ! communicator for the global group
    icomm_compute,   & ! communicator for the group of compute PEs
    icomm_asynio,    & ! communicator for the group of netcdf asynchronous IO PEs
    igroup_cart,     & ! group of the compute PEs
    icomm_cart,      & ! communicator for the virtual cartesian topology
    icomm_row,       & ! communicator for a east-west row of processors
    iexch_req          ! stores the sends requests for the neighbor-exchange
                       ! that can be used by MPI_WAIT to identify the send

USE data_parallel,      ONLY :  &
    imp_reals,       & ! determines the correct REAL type used in the model
                       ! for MPI
    imp_single,      & ! single precision REAL type for MPI
    imp_double,      & ! double precision REAL type for MPI
    imp_grib,        & ! determines the REAL type for the GRIB library
    imp_integers,    & ! determines the correct INTEGER type used in the model
                       ! for MPI
    imp_integ_ga,    & ! determines the correct INTEGER type used for grib_api
    imp_byte,        & ! determines the correct BYTE type used in the model
                       ! for MPI
    imp_character,   & ! determines the correct CHARACTER type used in the
                       ! model for MPI
    imp_logical,     & ! determines the correct LOGICAL   type used in the
                       ! model for MPI
    lcompute_pe,     & ! indicates whether this is a compute PE or not
    lreorder,        & ! during the creation of the virtual topology the
                       ! ranking of the processors may be reordered
    sendbuf,         & ! sending buffer for boundary exchange:
                       !   1-4 are used for sending, 5 is used for receiving
                       ! both buffers are allocated in organize_setup
    isendbuflen,     & ! length of one column of sendbuf
    intbuf,          & ! Buffers for distributing the Namelists
    realbuf,         & !
    logbuf,          & !
    charbuf            !

!------------------------------------------------------------------------------

USE data_io,            ONLY :  &
    irealgrib,       & ! KIND parameter for the Reals in the GRIB library
    ydate_ini,       & ! start of the forecast yyyymmddhh (year,month,day,hour)
    ydate_end,       & ! end   of the forecast yyyymmddhh (year,month,day,hour)
    ydate_bd,        & ! start of the forecast from which the 
                       ! boundary fields are used
    nuin,            & ! Unit number for Namelist INPUT files
    lmmss              ! 10/14 digits date format

!------------------------------------------------------------------------------

USE data_convection, ONLY :   &
    entr_sc,      & ! mean entrainment rate for shallow convection
    thick_sc        ! limit for convective clouds to be "shallow" (in Pa)

!------------------------------------------------------------------------------

!!USE data_gscp,       ONLY:    &  ! for old microphysics
USE gscp_data,       ONLY:    &
    v0snow,         & ! factor in the terminal velocity for snow
    mu_rain,        & !
    rain_n0_factor, & !
    cloud_num         ! cloud droplet number concentration

!------------------------------------------------------------------------------

USE data_soil,          ONLY :  &
    crsmin     ! minimum value of stomatal resistance
               ! (used by the Pen.-Mont. method for vegetation
               !  transpiration, itype_trvg=2)

!------------------------------------------------------------------------------

USE data_turbulence,    ONLY :  &
    rlam_mom,     & ! scaling factor of the laminar boudary layer for momentum
    rlam_heat,    & ! scaling factor of the laminar boudary layer for heat

    rat_lam,      & ! ratio of laminar scaling factors for vapour and heat
    rat_can,      & ! ratio of canop[y height over z0m
    rat_sea,      & ! ratio of laminar scaling factors for heat over sea and land

    z0m_dia,      & ! roughness length of a typical synoptic station

    c_lnd,        & ! surface area density of the roughness elements over land
                    ! [1/m]
    c_sea,        & ! surface area density of the waves over sea [1/m]
    c_soil,       & ! surface area density of the (evaporative) soil surface
    e_surf,       & ! exponent to get the effictive surface area

    tur_len,      & ! maximal turbulent length scale
    pat_len,      & ! length scale of subscale surface patterns over land

    a_heat,       & ! factor for turbulent heat transport
    a_mom,        & ! factor for turbulent momentum transport
    d_heat,       & ! factor for turbulent heat dissipation
    d_mom,        & ! factor for turbulent momentum dissipation
    c_diff,       & ! factor for turbulent diffusion of TKE
    a_hshr,       & ! factor for separate horizontal shear production
    a_stab,       & ! factor for stability correction of horizontal length scale

    clc_diag,     & ! cloud cover at saturation in statistical cloud diagnostic
    q_crit,       & ! critical value for normalized over-saturation

    tkhmin,       & ! minimal diffusion coefficients for heat
    tkmmin,       & ! minimal diffusion coefficients for momentum

    tkesmot,      & ! time smoothing factor for TKE and diffusion coefficients
    wichfakt,     & ! vertical smoothing factor for explicit diffusion tendencies
    securi          ! security factor for maximal diffusion coefficients

!------------------------------------------------------------------------------

USE src_sso,            ONLY :  &
    gkdrag,       & !
    gkwake

!------------------------------------------------------------------------------

USE utilities,          ONLY :  &
      elapsed_time,        & ! returns elapsed wall-clock time in seconds
      get_utc_date,        & ! actual date of the forecast in different forms
      phirot2phi,          & ! 
      rlarot2rla,          & ! 
      diff_minutes           !

!------------------------------------------------------------------------------

USE environment,              ONLY :  &
      init_environment, model_abort, init_procgrid, get_free_unit

!------------------------------------------------------------------------------

USE parallel_utilities,       ONLY :  &
    init_par_utilities, remark, distribute_values, global_values,       &
    gather_values

!------------------------------------------------------------------------------

USE vgrid_refatm_utils,       ONLY :  &
    refatm, set_refatm_defaults

USE src_block_fields,       ONLY :  init_block_fields

!------------------------------------------------------------------------------

#ifdef MESSY
! MESSy/BMIL
USE messy_main_mpi_bi,        ONLY: messy_mpi_initialize
USE messy_main_timer_bi,      ONLY: messy_timer_COSMO_reinit_time &
                                  , timer_message
USE messy_main_data_bi,       ONLY: lat_tot, lon_tot
! MESSy/SMCL
USE messy_main_timer,         ONLY: timer_get_calendar, timer_get_delta_time &
                                  , timer_get_date, time_span_d
#endif

!==============================================================================

IMPLICIT NONE

!==============================================================================

! Public and Private Subroutines

#ifdef SCLM
PUBLIC   grid_constants, constant_fields, input_tuning
#else
PUBLIC   organize_setup, constant_fields

PRIVATE  grid_constants, domain_decomposition, check_decomposition,         &
         input_lmgrid, input_runctl, input_tuning
#endif

!==============================================================================
! Module procedures
!==============================================================================

CONTAINS

!==============================================================================
#ifndef SCLM
!+ Module procedure in src_setup for the organization
!------------------------------------------------------------------------------

SUBROUTINE organize_setup

!------------------------------------------------------------------------------
!
! Description:
!  organize_setup is the driver routine for the initialization of the LM.
!  The main tasks are:
!   - Initializations 
!      Parallel or sequential environment, organizational variables.
!   - Input of all namelist groups
!      For every group is a special routine for reading this group named
!      "input_nameofgroup". The last group ("gribout") can appear several
!      times for different groups of variables that should be written.
!   - Domain decomposition in the parallel environment
!      The task of each subdomain is specified (i.e. the sizes of the 
!      subdomains are determined).
!
! Method:
!  See the sections of this subroutine.
!
! Input files:
!  File INPUT containing Namelist-groups for basic organization
!
! Output files:
!  File YUSPECIF containing the variables of every Namelist-group with default
!  and actual value.
!
!------------------------------------------------------------------------------
!
! Subroutine / Function arguments
! Scalar arguments with intent(in):

!------------------------------------------------------------------------------
!
! Local scalars:
INTEGER (KIND=iintegers)   ::       &
  ierrstat,        & ! error-code for Namelist input
  ierrstatv(3),        & ! another error-code for Namelist input
  istat,           & ! for local error-code
  ibuflen            ! length of the buffers

INTEGER                    ::       &
  nij,             & ! horizontal dimension
  niostat,         & ! for error-code of I/O
  izerror            ! 

INTEGER (KIND=iintegers)   ::    &
  nzjulianday        ! day of the year

REAL (KIND=wp)             ::    &
  zacthour           ! actual hour of the forecast

REAL (KIND=wp)             ::       &
  zdreal             ! for time-measuring   

CHARACTER (LEN=25)  yzroutine
CHARACTER (LEN=100) yzerrmsg 
CHARACTER (LEN= 9)  yinput       ! Namelist INPUT file

#ifdef MESSY
INTEGER(KIND =iintegers) :: syr, smo, sdy, shr, smi, sse
INTEGER(KIND =iintegers) :: ryr, rmo, rdy, rhr, rmi, rse
INTEGER(KIND =iintegers) :: time_passed,time_passed_julian, time_diff

INTEGER(KIND =iintegers) :: ICAL
REAL(KIND=wp)            :: rtime_passed
#endif

!- End of header
!==============================================================================

!------------------------------------------------------------------------------
!- Begin SUBROUTINE organize_setup
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
! Section 1: Initializations
!------------------------------------------------------------------------------

  yzroutine = 'organize_setup'
  ierrstat = 0
  ierrstatv(:) = 0
  yzerrmsg(:)  = ' '
  izerror  = 0

  !----------------------------------------------------------------------------
  ! Section 1.1: Initialization of the desired environment
  !----------------------------------------------------------------------------

  CALL init_environment (nproc, my_world_id, icomm_world, igroup_world,        &
                         imp_integers, imp_reals, imp_single, imp_double,      &
                         imp_grib, imp_byte, imp_character, imp_logical,       &
                         imp_integ_ga, iexch_req, irealgrib, yzerrmsg, izerror )

  IF (my_world_id == 0) THEN
    ! Working precision
                  PRINT*, ''
                  PRINT*, '    + + + + + + + + + + + + + + + +'
    IF (wp == dp) PRINT*, '    + RUNNING IN DOUBLE PRECISION +'
    IF (wp == sp) PRINT*, '    + RUNNING IN SINGLE PRECISION +'
                  PRINT*, '    + + + + + + + + + + + + + + + +'
                  PRINT*, ''

    PRINT *,'  SETUP OF THE LM'
    PRINT *,'    INITIALIZATIONS '
    PRINT*, ''
    PRINT *,'       Info about KIND-parameters:   iintegers / MPI_INT = ', iintegers, imp_integers
    PRINT *,'                                     int_ga    / MPI_INT = ', int_ga,    imp_integ_ga
  ENDIF

#ifdef MESSY
  CALL messy_mpi_initialize
#endif

  !----------------------------------------------------------------------------
  ! Section 1.2: Initialization of the timing
  !----------------------------------------------------------------------------

  CALL elapsed_time (zdreal, istat)
  IF (istat == 0) THEN
    lclock = .TRUE.
  ELSE
    CALL remark (my_world_id, yzroutine,                            &
                 ' WARNING:     !!! NO SYSTEM CLOCK PRESENT !!! ')
    lclock = .FALSE.
  ENDIF

  !----------------------------------------------------------------------------
  ! Section 1.3: Initialization of organizational variables
  !----------------------------------------------------------------------------

  ! Get free unit numbers for nuin, nuspecif, nudebug
  CALL get_free_unit (nuin)
  CALL get_free_unit (nuspecif)
  CALL get_free_unit (nudebug)

  ! Variables for handling the different time levels
  nold     = 3
  nnow     = 1
  nnew     = 2
  ntke     = 0

  ! Allocate space for sending Namelist buffers
  ibuflen  = 2000    ! should be long enough for very long Namelists
  ALLOCATE ( intbuf(ibuflen)   , STAT=istat )
  intbuf (:) = 0
  ALLOCATE ( realbuf(ibuflen)  , STAT=istat )
  realbuf(:) = 0.0_wp
  ALLOCATE ( logbuf(ibuflen)   , STAT=istat )
  logbuf (:) = .FALSE.
  ALLOCATE ( charbuf(ibuflen)  , STAT=istat )
  charbuf(:) = ' '

!------------------------------------------------------------------------------
! Section 2: Read and distribute NAMELIST-variables for basic organization
!------------------------------------------------------------------------------

  !----------------------------------------------------------------------------
  ! Section 2.1: Prepare NAMELIST-input
  !----------------------------------------------------------------------------

  IF (my_world_id == 0) THEN
    PRINT *,'    INPUT OF THE NAMELISTS'

    ! Open files for input of the NAMELISTS and control output
    yinput   = 'INPUT_ORG'

    OPEN(nuin   , FILE=yinput  , FORM=  'FORMATTED', STATUS='UNKNOWN',  &
         IOSTAT=niostat)
    IF(niostat /= 0) THEN
      yzerrmsg = ' ERROR    *** Error while opening file INPUT *** '
      ierrstat = 1001
      CALL model_abort (my_world_id, ierrstat, yzerrmsg, yzroutine)
    ENDIF

    OPEN(nuspecif, FILE=yuspecif, FORM=  'FORMATTED', STATUS='REPLACE',  &
         IOSTAT=niostat)
    IF(niostat /= 0) THEN
      yzerrmsg = ' ERROR    *** Error while opening file YUSPECIF *** '
      ierrstat = 1001
      CALL model_abort (my_world_id, ierrstat, yzerrmsg, yzroutine)
    ENDIF
    REWIND nuspecif

    ! Print a headline in file YUSPECIF
    WRITE (nuspecif, '(A2)')  '  '
    WRITE (nuspecif, '(A55)')                                                 &
                   '0     The NAMELIST variables were specified as follows:'
    WRITE (nuspecif, '(A55)')                                                 &
                   '      ================================================='
    WRITE (nuspecif, '(A2)')  '  '
  ENDIF

  !----------------------------------------------------------------------------
  ! Section 2.2: Read the NAMELIST-variables
  !----------------------------------------------------------------------------

  ! Read all NAMELIST-groups
  CALL input_lmgrid (nuspecif, nuin, ierrstatv(1))

  IF (ierrstatv(1) < 0) THEN
    yzerrmsg = ' ERROR    *** while reading NAMELIST Group /LMGRID/ ***'
    CALL model_abort (my_world_id, ierrstatv(1), yzerrmsg, yzroutine)
  ENDIF

  CALL input_runctl (nuspecif, nuin, ierrstatv(2))

  IF (ierrstatv(2) < 0) THEN
    yzerrmsg = ' ERROR    *** while reading NAMELIST Group /RUNCTL/ ***'
    CALL model_abort (my_world_id, ierrstatv(2), yzerrmsg, yzroutine)
  ENDIF

  CALL input_tuning (nuspecif, nuin, ierrstatv(3))

  IF (ierrstatv(3) < 0) THEN
    yzerrmsg = ' ERROR    *** while reading NAMELIST Group /TUNING/ ***'
    CALL model_abort (my_world_id, ierrstatv(3), yzerrmsg, yzroutine)
  ENDIF

  IF (my_world_id == 0) THEN
    ! Close file for input of the NAMELISTS
    CLOSE (nuin    , STATUS='KEEP')

    IF (ANY(ierrstatv /= 0)) THEN
      ierrstat = 1002
      yzerrmsg  = ' ERROR    *** Wrong values in NAMELIST INPUT_ORG ***'
      CALL model_abort (my_world_id, ierrstat, yzerrmsg, yzroutine)
    ENDIF
  ENDIF

!------------------------------------------------------------------------------
! Section 3: Further Initializations: Constants, Date, Coverpage
!------------------------------------------------------------------------------

  ! compute constants (scalars concerned with the grid)
  CALL set_constants

  degrad   =   pi / 180.0_wp
  raddeg   =   180.0_wp / pi

#ifdef MESSY
  CALL messy_setup
  ! 1. SET TIME STEP DT
  CALL timer_get_delta_time(ierrstat, dt)
  CALL timer_message(ierrstat, yzroutine)

  ! 2. SET CALENDER
  CALL timer_get_calendar(ierrstat, ICAL)
  CALL timer_message(ierrstat, yzroutine)

  SELECT CASE(ICAL)
  CASE(1)
     itype_calendar = 1
  CASE DEFAULT
     ! JULIAN at the moment should become gregorian
     itype_calendar = 0
  END SELECT

  ! 3. start_date
  CALL timer_get_date(ierrstat, 'start', syr, smo, sdy, shr, smi, sse)
  CALL timer_message(ierrstat, yzroutine )
  WRITE ( ydate_ini(1:4) , '(I4.4)' ) syr
  WRITE ( ydate_ini(5:6) , '(I2.2)' ) smo
  WRITE ( ydate_ini(7:8) , '(I2.2)' ) sdy
  WRITE ( ydate_ini(9:10), '(I2.2)' ) shr
  WRITE ( ydate_ini(11:12),'(I2.2)' ) smi
  WRITE ( ydate_ini(13:14),'(I2.2)' ) sse

  lmmss = .TRUE.
  ydate_bd = ydate_ini

  CALL messy_timer_COSMO_reinit_time

  ! 5. stop date
  CALL timer_get_date(ierrstat, 'stop', ryr, rmo, rdy, rhr, rmi, rse)
  CALL timer_message(ierrstat, yzroutine)

  WRITE ( ydate_end(1:4) , '(I4.4)' ) ryr
  WRITE ( ydate_end(5:6) , '(I2.2)' ) rmo
  WRITE ( ydate_end(7:8) , '(I2.2)' ) rdy
  WRITE ( ydate_end(9:10), '(I2.2)' ) rhr
  WRITE ( ydate_end(11:12),'(I2.2)' ) rmi
  WRITE ( ydate_end(13:14),'(I2.2)' ) rse

  CALL time_span_d(rtime_passed,syr,smo,sdy,shr,smi, sse &
       ,ryr,rmo,rdy,rhr,rmi,rse)
  hstop = rtime_passed * 24._wp
  nstop = INT(hstop*3600._wp/dt)
#endif

  ! compute the actual date
  ntstep      = nstart
  CALL get_utc_date(ntstep, ydate_ini, dt, itype_calendar, yakdat1,    &
                    yakdat2, nzjulianday, zacthour)

!------------------------------------------------------------------------------
! Section 4: Domain Decomposition
!------------------------------------------------------------------------------

  ! Allocate space for isubpos and sendbuf
  ALLOCATE ( isubpos(0:num_compute-1,4)   , STAT=istat )
  isubpos(:,:) = 0

  IF (num_compute > 1) THEN
    ! Allocate the sendbuffer with the maximal size.
    isendbuflen =                                                           &
         (MAX(ie_tot/nprocx+1+2*nboundlines,je_tot/nprocy+1+2*nboundlines)  &
           *nboundlines*(ke_tot+1)) * 24
    ALLOCATE (sendbuf(isendbuflen,8) , STAT=istat )
    sendbuf(:,:) = 0.0_wp
  ELSE
    ! sendbuf is not needed in this case, since it is only passed as
    ! externally provided storage space for exchg_boundaries(), which in
    ! turn uses it only for MPI communication, i.e., when num_compute > 0.
    ! However, because now exchg_boundaries() is also called during
    ! 1-processor runs (doing only the periodic exchanges and no MPI),
    ! we have to provide it in an allocated state, since some
    ! compilers (e.g., intel fortran) will complain when debug options
    ! are turned on. 
    ! The clean solution would be to declare and allocate sendbuf
    ! locally in exchg_boundaries by someting like
    !    REAL, allocatable, save :: sendbuf
    !    if (.not.allocated(sendbuf)) allocate(sendbuf(isendbuflen))
    ! and eliminate it from the rest of the code.
    ! As an intermediate working solution, provide some dummy space
    ! here:
    isendbuflen = 1
    ALLOCATE(sendbuf(isendbuflen,8) , STAT=istat )
    sendbuf(:,:) = 0.0_wp
  ENDIF

  IF (istat /= 0) THEN
    ierrstat = 1003
    yzerrmsg  = ' ERROR    *** Allocation of space for isubpos failed ***'
    CALL model_abort (my_world_id, ierrstat, yzerrmsg, yzroutine)
  ENDIF

  ! Initialize the cartesian processor grid
  !  One argument added to this routine for OASIS coupling
  !  icomm_world = MPI_COMM_WORLD if no OASIS coupling
  CALL init_procgrid (                                                         &
        nproc, nprocx, nprocy, nprocio, nc_asyn_io, lperi_x, lperi_y,          &
        lreproduce, lreorder, icomm_world, my_world_id,                        &
        icomm_compute, icomm_asynio, icomm_cart, igroup_cart, my_cart_id,      &
        my_cart_pos, my_cart_neigh, icomm_row, lcompute_pe, yzerrmsg, izerror)

  IF (izerror /= 0) THEN
    CALL model_abort (my_world_id, 1004, yzerrmsg, yzroutine, izerror)
  ENDIF

  IF ( lcompute_pe ) THEN
    CALL domain_decomposition
  ELSE
    ke = ke_tot
  ENDIF

  ! Compute constants related to the grid
  CALL grid_constants

  ! Initialize the utility module parallel_utilities
  CALL init_par_utilities                                                     &
   (ie, je, ke, ie_tot, je_tot, ke_tot, ie_max, je_max,                       &
    istartpar, iendpar, jstartpar, jendpar, nproc, nprocx, nprocy, nprocio,   &
    isubpos, nboundlines, icomm_cart, my_cart_id, imp_reals, imp_integers)

  ! In Debug-mode, control information about the decomposition is sent to
  ! the root process and printed
  IF ( (idbg_level > 5) .AND. (num_compute > 1) .AND. (lcompute_pe)) THEN
    CALL check_decomposition (yzerrmsg, izerror)
  ENDIF

!------------------------------------------------------------------------------
! Section 5: Computation of index-arrays for re-shuffling of data layout for 
!            the block physics
!------------------------------------------------------------------------------

  IF (lcompute_pe) THEN

     nij = (iendpar-istartpar+1)*(jendpar-jstartpar+1)


     !Set nproma and nblock
     ! If both nproma and nblock are set in the input namelist
     ! the value of nblock is used
     IF (nblock > 0)  THEN !use nblock from namelist, set nproma accordingly
        IF (MOD(nij,nblock) == 0) THEN
           nproma = INT( nij/nblock )
           nlastproma = nproma
        ELSE
           nproma = INT( nij/nblock ) + 1
           nlastproma = MOD(nij,nproma)
        END IF

     ELSE !use nproma from namelist, set nblock accordingly
        ! Special treatment for nproma = -1 (set nblock=1) 
        ! and nproma=-2
        IF (nproma==-1) THEN
           nproma=nij
        ELSEIF (nproma==-2) THEN
           nproma=(iendpar-istartpar+1)
        END IF
        ! Compute nblock, nlastproma
        IF (MOD(nij,nproma) == 0) THEN
           nblock     = INT (nij/nproma)
           nlastproma = nproma
        ELSE
           nblock     = INT(nij/nproma) + 1
           nlastproma = MOD(nij,nproma)
        ENDIF
     END IF

     CALL init_block_fields(istartpar,iendpar,jstartpar,jendpar,&
          nproma,nlastproma,nblock,izerror, yzerrmsg)

     IF (izerror /= 0) THEN
        CALL model_abort (my_world_id, izerror, yzerrmsg,       &
             'src_setup:init_block_fields')
     ENDIF

  END IF

!------------------------------------------------------------------------------
!  End of the Subroutine
!------------------------------------------------------------------------------

END SUBROUTINE organize_setup

!==============================================================================
!+ Module procedure in "setup" for the input of NAMELIST lmgrid
!------------------------------------------------------------------------------

SUBROUTINE input_lmgrid (nuspecif, nuin, ierrstat)

!------------------------------------------------------------------------------
!
! Description:
!   This subroutine organizes the input of the NAMELIST-group lmgrid. 
!   The group lmgrid contains variables defining the rotated grid, its 
!   location on the globe, the size of the model domain and the resolution.
!
! Method:
!   All variables are initialized with default values and then read in from
!   the file INPUT. The input values are checked for errors and for 
!   consistency. If wrong input values are detected the program prints 
!   an error message. The program is not stopped in this routine but an 
!   error code is returned to the calling routine that aborts the program after
!   reading in all other namelists. 
!   In parallel mode, the variables are distributed to all nodes with the
!   environment-routine distribute_values.    
!   Both, default and input values are written to the file YUSPECIF 
!   (specification of the run).
!
!------------------------------------------------------------------------------

! Subroutine / Function arguments
  INTEGER   (KIND=iintegers),   INTENT (IN)      ::        &
    nuspecif,     & ! Unit number for protocolling the task
    nuin            ! Unit number for Namelist INPUT file

  INTEGER   (KIND=iintegers),   INTENT (OUT)   ::        &
    ierrstat        ! error status variable

! Local variables
  REAL (KIND=wp)             ::       &
    p0sl, p0sl_d,         & ! constant reference pressure on sea-level
    t0sl, t0sl_d,         & ! constant reference temperature on sea-level
    dt0lp, dt0lp_d,       & ! d (t0) / d (ln p0)
    delta_t, delta_t_d,   & ! temp. difference between sea level and stratosphere 
                            ! (for irefatm = 2)
    h_scal,  h_scal_d       ! scale height (for irefatm = 2)

  INTEGER (KIND=iintegers)    ::                                   &
    irefatm, irefatm_d      ! type of the reference atmosphere

! Variables for default values
  REAL (KIND=wp)             ::       &
    pollon_d,      & ! longitude of the rotated north pole (in degrees, E>0)
    pollat_d,      & ! latitude of the rotated north pole (in degrees, N>0)
    polgam_d,      & ! angle between the north poles of the systems
    dlon_d,        & ! grid point distance in zonal direction (in degrees)
    dlat_d,        & ! grid point distance in meridional direction (in degrees)
    startlon_tot_d,& ! transformed longitude of the lower left grid point
                     ! of the total domain (in degrees, E>0)
    startlat_tot_d   ! transformed latitude of the lower left grid point
                     ! of the total domain (in degrees, N>0)

  INTEGER (KIND=iintegers)   ::       &
    ie_tot_d,     & ! number of grid points in zonal direction
    je_tot_d,     & ! number of grid points in meridional direction
    ke_tot_d        ! number of grid points in vertical direction

  INTEGER (KIND=iintegers)   :: ierr, iz_err

  CHARACTER(LEN=250)         :: iomsg_str

! Define the namelist group
  NAMELIST /lmgrid/ pollon, pollat, polgam, dlon, dlat, startlon_tot,      &
                    startlat_tot, ie_tot, je_tot, ke_tot,                  &
                    irefatm, p0sl, t0sl, dt0lp, delta_t, h_scal

!------------------------------------------------------------------------------
!- End of header -
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Begin SUBROUTINE input_lmgrid
!------------------------------------------------------------------------------

ierrstat = 0_iintegers
iz_err = 0_iintegers

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 1: Initialize the default variables
!------------------------------------------------------------------------------

  pollon_d       = -170.0_wp
  pollat_d       =   32.5_wp
  polgam_d       =    0.0_wp
  dlon_d         =    0.008_wp
  dlat_d         =    0.008_wp
  startlon_tot_d =   -1.252_wp
  startlat_tot_d =   -7.972_wp

  ie_tot_d       = 51
  je_tot_d       = 51
  ke_tot_d       = 20

  ! default values of the reference-atmosphere
  irefatm_d      = 2
  p0sl_d         =   1.0E5_wp
  t0sl_d         =  288.15_wp
  dt0lp_d        =    42.0_wp
  delta_t_d      =    75.0_wp
  h_scal_d       = 10000.0_wp

!------------------------------------------------------------------------------
!- Section 2: Initialize variables with default
!------------------------------------------------------------------------------

  pollon       = pollon_d
  pollat       = pollat_d
  polgam       = polgam_d
  dlon         = dlon_d
  dlat         = dlat_d
  startlon_tot = startlon_tot_d
  startlat_tot = startlat_tot_d

  ie_tot       = ie_tot_d 
  je_tot       = je_tot_d 
  ke_tot       = ke_tot_d 

  ! values of the reference-atmosphere
  irefatm      = irefatm_d
  p0sl         = p0sl_d
  t0sl         = t0sl_d
  dt0lp        = dt0lp_d
  delta_t      = delta_t_d
  h_scal       = h_scal_d

!------------------------------------------------------------------------------
!- Section 3: Input of the namelist values
!------------------------------------------------------------------------------

  iomsg_str(:) = ' '
  READ (nuin, lmgrid, IOSTAT=iz_err, IOMSG=iomsg_str)

  IF (iz_err /= 0) WRITE (*,'(A,A)') 'Namelist-ERROR LMGRID: ', TRIM(iomsg_str)
ENDIF

IF (nproc > 1) THEN
  ! distribute error status to all processors
  CALL distribute_values  (iz_err, 1, 0, imp_integers,  icomm_world, ierr)
ENDIF

IF (iz_err /= 0) THEN
  ierrstat = -1
  RETURN
ENDIF

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 4: Check values for errors and consistency
!------------------------------------------------------------------------------

! -180.0 <= pollon, polgam, startlon_tot <= 180.0
!US have to remove this check for southern hemisphere
!US  IF ( (-180.0_wp > pollon) .OR. (pollon > 180.0_wp) ) THEN
!US    PRINT *,' *** WRONG VALUE OF VARIABLE pollon: ',pollon,'  ***'
!US    ierrstat = 1002
!US  ENDIF
!US  IF ( (-180.0_wp > polgam) .OR. (polgam > 180.0_wp) ) THEN
!US    PRINT *,' *** WRONG VALUE OF VARIABLE polgam: ',polgam,'  ***'
!US    ierrstat = 1002
!US  ENDIF
  IF ((-180.0_wp > startlon_tot) .OR. (startlon_tot > 180.0_wp)) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE startlon_tot: ',startlon_tot,'  ***'
    ierrstat = 1002
  ENDIF

! -90.0 <= pollat, startlat_tot <= 90.0
!US have to remove this check for southern hemisphere
!US  IF ((-90.0_wp > pollat) .OR. (pollat > 90.0_wp)) THEN
!US    PRINT *,' *** WRONG VALUE OF VARIABLE pollat: ',pollat,'  ***'
!US    ierrstat = 1002
!US  ENDIF
  IF ( (-90.0_wp > startlat_tot) .OR. (startlat_tot > 90.0_wp) ) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE startlat_tot: ',startlat_tot,'  ***'
    ierrstat = 1002
  ENDIF

! dlon, dlat > epsilon
  IF (dlon < 1E-6_wp) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE dlon:  ',dlon,'  *** '
    ierrstat = 1002
  ENDIF
  IF (dlat < 1E-6_wp) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE dlat:  ',dlat,'  *** '
    ierrstat = 1002
  ENDIF

! ie_tot, je_tot >= 3, ke >= 1
  IF (ie_tot < 3) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE ie_tot:  ',ie_tot,'  *** '
    ierrstat = 1002
  ENDIF
  IF (je_tot < 3) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE je_tot:  ',je_tot,'  *** '
    ierrstat = 1002
  ENDIF
  IF (ke_tot < 1) THEN
    PRINT *,' *** WRONG VALUE OF VARIABLE ke_tot:  ',ke_tot,'  *** '
    ierrstat = 1002
  ENDIF

! Check values for reference atmosphere
  ! test if p0sl is meaningful
  IF ((p0sl < 90000.0_wp) .OR. (p0sl > 110000.0_wp)) THEN
    PRINT *, ' *** ERROR:  p0sl must be in the range 90000.0 ... 110000.0 *** '
    ierrstat = 1011
  ENDIF

  ! test if t0sl is meaningful
  IF ((t0sl < 270.0_wp) .OR. (t0sl > 300.0_wp)) THEN
    PRINT *, ' *** ERROR:  t0sl must be in the range 270.0 ... 300.0 *** '
    ierrstat = 1012
  ENDIF

  IF     (irefatm == 1) THEN
    ! test if dt0lp for LM is non-negative
    IF (dt0lp  < 0.0_wp) THEN
      PRINT *, ' *** ERROR:  dt0lp < 0.0 is not allowed ***'
      ierrstat = 1013
    ENDIF
  ELSEIF (irefatm == 2) THEN
    ! test for reasonable values of delta_t
    IF ( (delta_t  < 50.0_wp) .OR. (delta_t > 100.0_wp) ) THEN
      PRINT *, ' *** ERROR:  delta_t must be in the range 50.0 ... 100.0 *** '
      PRINT *, ' ***         but is delta_t = ', delta_t
      ierrstat = 1014
    ENDIF

    ! test for reasonable values of h_scal
    IF ( (h_scal  < 7000.0_wp) .OR. (h_scal > 12000.0_wp) ) THEN
      PRINT *, ' *** ERROR:  h_scal must be in the range 7000.0 ... 12000.0 *** '
      PRINT *, ' ***         but is h_scal  = ', h_scal
      ierrstat = 1015
    ENDIF
  ENDIF

ENDIF

!------------------------------------------------------------------------------
!- Section 5: Distribute variables to all nodes
!------------------------------------------------------------------------------

IF (nproc > 1) THEN

  IF (my_world_id == 0) THEN
    intbuf  ( 1) = ie_tot
    intbuf  ( 2) = je_tot
    intbuf  ( 3) = ke_tot
    intbuf  ( 4) = irefatm
    realbuf ( 1) = pollon
    realbuf ( 2) = pollat
    realbuf ( 3) = polgam
    realbuf ( 4) = dlon
    realbuf ( 5) = dlat
    realbuf ( 6) = startlat_tot
    realbuf ( 7) = startlon_tot
    realbuf ( 8) = p0sl
    realbuf ( 9) = t0sl
    realbuf (10) = dt0lp
    realbuf (11) = delta_t
    realbuf (12) = h_scal
  ENDIF

  CALL distribute_values  (realbuf, 12, 0, imp_reals,    icomm_world, ierr)
  CALL distribute_values  (intbuf ,  4, 0, imp_integers, icomm_world, ierr)

  IF (my_world_id /= 0) THEN
    ie_tot       = intbuf  ( 1)
    je_tot       = intbuf  ( 2)
    ke_tot       = intbuf  ( 3)
    irefatm      = intbuf  ( 4)
    pollon       = realbuf ( 1)
    pollat       = realbuf ( 2)
    polgam       = realbuf ( 3)
    dlon         = realbuf ( 4)
    dlat         = realbuf ( 5)
    startlat_tot = realbuf ( 6)
    startlon_tot = realbuf ( 7)
    p0sl         = realbuf ( 8)
    t0sl         = realbuf ( 9)
    dt0lp        = realbuf (10)
    delta_t      = realbuf (11)
    h_scal       = realbuf (12)
  ENDIF

ENDIF

! Compute endlat_tot, endlon_tot
endlat_tot = startlat_tot + (je_tot-1)*dlat
endlon_tot = startlon_tot + (ie_tot-1)*dlon
IF (endlon_tot > 180.0_wp) THEN
  endlon_tot = endlon_tot - 360.0_wp
ENDIF

! allocate the structures refatm and vcoord
#ifndef I2CINC
CALL set_refatm_defaults
#endif

! put the values of the reference atmosphere to the structure refatm
refatm%irefatm = irefatm
refatm%p0sl    = p0sl
refatm%t0sl    = t0sl
refatm%dt0lp   = dt0lp
refatm%delta_t = delta_t
refatm%h_scal  = h_scal

!------------------------------------------------------------------------------
!- Section 6: Output of the namelist variables and their default values
!------------------------------------------------------------------------------

IF (my_world_id == 0) THEN

  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(A23)') '0     NAMELIST:  lmgrid'
  WRITE (nuspecif, '(A23)') '      -----------------'
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(T7,A,T33,A,T51,A,T70,A)') 'Variable', 'Actual Value',   &
                                               'Default Value', 'Format'

  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'pollon ',pollon ,pollon_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'pollat ',pollat ,pollat_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'polgam ',polgam ,polgam_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'dlon   ',dlon   ,dlon_d   ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'dlat   ',dlat   ,dlat_d   ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                      'startlon_tot  ',startlon_tot  ,startlon_tot_d  ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                      'startlat_tot  ',startlat_tot  ,startlat_tot_d  ,' R '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                           'ie_tot', ie_tot ,ie_tot_d ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                           'je_tot', je_tot ,je_tot_d ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                           'ke_tot', ke_tot ,ke_tot_d ,' I '
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(T7,A)')  'Variables of the reference atmosphere:'
  WRITE (nuspecif, '(T9,A)')  '(Are only in effect, if input data are in GRIB2!!)'
  WRITE (nuspecif, '(T7,A,T33,A,T51,A,T70,A)') 'Variable', 'Actual Value',   &
                                               'Default Value', 'Format'
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                        'irefatm', irefatm, irefatm_d ,' I '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                                 'p0sl', p0sl, p0sl_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                                 't0sl', t0sl, t0sl_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                              'dt0lp', dt0lp, dt0lp_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                        'delta_t', delta_t, delta_t_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'h_scal', h_scal, h_scal_d ,' R '
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(A2)')  '  '
ENDIF

!------------------------------------------------------------------------------
!- End of the Subroutine
!------------------------------------------------------------------------------

END SUBROUTINE input_lmgrid

!==============================================================================
!+ Module procedure in "setup" for the input of NAMELIST runctl
!------------------------------------------------------------------------------

SUBROUTINE input_runctl (nuspecif, nuin, ierrstat)

!------------------------------------------------------------------------------
!
! Description:
!   This subroutine organizes the input of the NAMELIST-group runctl. 
!   The group runctl contains variables for controlling the model-run:
!     - begin and end of the forecast
!     - start date of the forecast for initial and boundary fields
!     - number of the experiment (for documentation purposes)
!     - controlling of reading and writing ready-files
!     - increments for deleting tmin, tmax, vbmax
!     - logical variables for certain actions
!
! Method:
!   All variables are initialized with default values and then read in from
!   the file INPUT. The input values are checked for errors and for
!   consistency. If wrong input values are detected the program prints
!   an error message. The program is not stopped in this routine but an
!   error code is returned to the calling routine that aborts the program after
!   reading in all other namelists.
!   In parallel mode, the variables are distributed to all nodes with the
!   environment-routine distribute_values.   
!   Both, default and input values are written to the file YUSPECIF
!   (specification of the run).
!
!------------------------------------------------------------------------------

! Subroutine / Function arguments
  INTEGER   (KIND=iintegers),   INTENT (IN)      ::        &
    nuspecif,     & ! Unit number for protocolling the task
    nuin            ! Unit number for Namelist INPUT file

  INTEGER   (KIND=iintegers),   INTENT (OUT)   ::        &
    ierrstat        ! error status variable

! Local variables

! Variables for default values
  INTEGER (KIND=iintegers)   ::       &
    nstop_d,             & ! last time step of the forecast
    nprocx_d,            & ! number of processors in x-direction (ie)
    nprocy_d,            & ! number of processors in y-direction (je)
    nprocio_d,           & ! number of processors for (asynchronous) I/O
    num_asynio_comm_d,   & ! number of asynchronous I/O communicators (netcdf)
    num_iope_percomm_d,  & ! number of asynchronous I/O PE per communicator (netcdf)
    nboundlines_d,       & ! number of boundary lines for every processor
    ncomm_type_d,        & ! type of communication
    nproma_d,            & ! block size for physical parameterizations
    nblock_d,            & ! number of blocks for physical parameterizations
    itype_calendar_d,    & ! use a climatological year with 360 days
    idbg_level_d,        & ! controlling verbosity of output
    itype_timing_d         ! determines how to handle the timing

  REAL (KIND=wp)             ::       &
    dt_d,                & ! length of time step in seconds
    hstart_d,            & ! start of the forecast in hours - default value
    hstop_d,             & ! end of the forecast in hours - default value
    hincmxt_d,           & ! hour increment for deleting tmin, tmax  - default
    hincmxu_d              ! hour increment for deleting vbmax - default

  LOGICAL                    ::       &
    ldatatypes_d,        & ! if .TRUE.: use MPI-Datatypes for some communications
    ltime_barrier_d,     & !if .TRUE.: use additional barriers for determining the
                           ! load-imbalance
    luseobs_d,           & ! on - off switch for using observational data
    leps_d,              & ! if .TRUE., running in ensemble mode (EPS)
    lsppt_d,             & ! if .TRUE., switch on stoch. phys. tend. perturbations
    lphys_d,             & ! switch for running the physics
    ldiagnos_d,          & ! switch for running the diagnostics
    ldfi_d,              & ! switch for running the digital filtering
    luse_rttov_d,        & ! if rttov-library is used
    luse_radarfwo_d,     & ! if .TRUE., switch on the radar forward operator
    l_cosmo_art_d,       & ! if .TRUE., run the COSMO_ART
    l_pollen_d,          & ! if .TRUE., run the Pollen component
    ltraj_d,             & ! if .TRUE., compute trajectories
    lroutine_d,          & ! if .TRUE., run an operational forecast
    llm_d,               & ! if .TRUE., running with a lowered upper boundary
    ldump_ascii_d,       & ! to flush the ASCII files
    lreproduce_d,        & ! the results are reproducible in parallel mode
    lreorder_d,          & ! reordering of the processor ranking
    lartif_data_d,       & ! forecast with self-defined artificial data
    lperi_x_d,           & ! lartif_data=.TRUE.:  periodic boundary conditions
                           !            =.FALSE.: with Davies conditions
    lperi_y_d,           & ! lartif_data=.TRUE.:  periodic boundary conditions
                           !            =.FALSE.: with Davies conditions
    l2dim_d                ! lartif_data=.TRUE.:  2dimensional model version
                           !            =.FALSE.: full 3dimensional version

  LOGICAL                    ::       &
    ldebug_dyn_d,        & ! if .TRUE., debug output for dynamics
    ldebug_gsp_d,        & ! if .TRUE., debug output for grid scale precipitation
    ldebug_rad_d,        & ! if .TRUE., debug output for radiation
    ldebug_tur_d,        & ! if .TRUE., debug output for turbulence
    ldebug_con_d,        & ! if .TRUE., debug output for convection
    ldebug_soi_d,        & ! if .TRUE., debug output for soil model
    ldebug_io_d ,        & ! if .TRUE., debug output for I/O
    ldebug_mpe_d,        & ! if .TRUE., debug output for mpe_io
    ldebug_dia_d,        & ! if .TRUE., debug output for diagnostics
    ldebug_art_d,        & ! if .TRUE., debug output for COSMO_ART
    ldebug_ass_d,        & ! if .TRUE., debug output for assimilation
    ldebug_lhn_d,        & ! if .TRUE., debug output for latent heat nudging
    linit_fields_d,      & ! to choose whether to initialize fields
    lprintdeb_all_d        ! .TRUE.:  all tasks print debug output
                           ! .FALSE.: only task 0 prints debug output

  CHARACTER (LEN=14)  :: ydate_ini_d, tmpdate_ini, tmpdate_ini_d ! start of the forecast
  CHARACTER (LEN=14)  :: ydate_end_d, tmpdate_end, tmpdate_end_d ! end   of the forecast
  CHARACTER (LEN=14)  :: ydate_bd_d,  tmpdate_bd,  tmpdate_bd_d  
                         ! start of the forecast from which the boundary fields are used

! Other Variables
  INTEGER (KIND=iintegers)   ::       &
    ierr, iz_err

  INTEGER  (KIND=intgribf)   ::       &
    iniyy, inimm, inidd, inihh, inimi, iniss,                               &
    indyy, indmm, inddd, indhh, indmi, indss, imindif, ierrf

! Define the namelist group
  NAMELIST /runctl/ nstop, hstart, hstop, dt,                               &
                    ydate_ini, ydate_bd, lphys, ldiagnos, ldfi, luseobs,    &
                    hincmxt, hincmxu, idbg_level, itype_timing,             &
                    lreproduce, lreorder, lperi_x, lperi_y, l2dim,          &
                    lartif_data, llm, lroutine,                             &
                    nprocx, nprocy, nprocio, num_asynio_comm,               &
                    num_iope_percomm, nboundlines, ncomm_type,              &
                    ldatatypes, ltime_barrier, luse_rttov, itype_calendar,  &
                    leps, ldump_ascii, ldebug_dyn, ldebug_gsp, ldebug_rad,  &
                    ldebug_tur, ldebug_con, ldebug_soi, ldebug_io ,         &
                    ldebug_mpe, ldebug_dia, ldebug_art, ldebug_ass,         &
                    ldebug_lhn, lprintdeb_all, linit_fields, ydate_end,     &
                    l_cosmo_art, l_pollen, luse_radarfwo, ltraj,            &
                    nproma, nblock, lsppt

!------------------------------------------------------------------------------
!- End of header -
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Begin SUBROUTINE input_runctl
!------------------------------------------------------------------------------

ierrstat = 0_iintegers
iz_err = 0_iintegers
ierrf  = 0_intgribf

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 1: Initialize the default variables
!------------------------------------------------------------------------------

  nstop_d         =  0_iintegers
  nprocx_d        =  1_iintegers
  nprocy_d        =  1_iintegers
  nprocio_d       =  0_iintegers
  num_asynio_comm_d    = 0_iintegers
  num_iope_percomm_d   = 0_iintegers
  nboundlines_d   =  2_iintegers
  ncomm_type_d    =  1_iintegers
  nproma_d        =  16
  nblock_d        =  -1
  ldatatypes_d    =  .FALSE.
  ltime_barrier_d =  .FALSE.
  luse_rttov_d    =  .FALSE.
  luse_radarfwo_d =  .FALSE.

  hstart_d        =  0.0_wp
  hstop_d         =  0.0_wp
  hincmxt_d       =  6.0_wp
  hincmxu_d       =  1.0_wp
  dt_d            = 30.0_wp

  leps_d          = .FALSE.
  lphys_d         = .TRUE.
  lsppt_d         = .FALSE.
  ldiagnos_d      = .TRUE.
  ldfi_d          = .FALSE.
  luseobs_d       = .FALSE.
  ldump_ascii_d   = .TRUE.
  lreproduce_d    = .TRUE.
  lreorder_d      = .FALSE.
  lartif_data_d   = .FALSE.
  lperi_x_d         = .FALSE.
  lperi_y_d         = .FALSE.
  l2dim_d         = .FALSE.
  lroutine_d      = .FALSE.
  llm_d           = .FALSE.
  l_cosmo_art_d   = .FALSE.
  l_pollen_d      = .FALSE.
  ltraj_d         = .FALSE.
  idbg_level_d    =  2
  itype_timing_d  =  4
  itype_calendar_d=  0

  ldebug_dyn_d    = .FALSE.
  ldebug_gsp_d    = .FALSE.
  ldebug_rad_d    = .FALSE.
  ldebug_tur_d    = .FALSE.
  ldebug_con_d    = .FALSE.
  ldebug_soi_d    = .FALSE.
  ldebug_io_d     = .FALSE.
  ldebug_mpe_d    = .FALSE.
  ldebug_dia_d    = .FALSE.
  ldebug_art_d    = .FALSE.
  ldebug_ass_d    = .FALSE.
  ldebug_lhn_d    = .FALSE.
  lprintdeb_all_d = .FALSE.
  linit_fields_d  = .FALSE.

  ydate_ini_d     = '              '
  ydate_end_d     = '              '
  ydate_bd_d      = '              '

!------------------------------------------------------------------------------
!- Section 2: Initialize variables with defaults
!------------------------------------------------------------------------------

  nstop         = nstop_d
  nprocx        = nprocx_d
  nprocy        = nprocy_d
  nprocio       = nprocio_d
  num_asynio_comm   = num_asynio_comm_d
  num_iope_percomm  = num_iope_percomm_d
  nboundlines   = nboundlines_d
  ncomm_type    = ncomm_type_d
  nproma        = nproma_d
  nblock        = nblock_d
  ldatatypes    = ldatatypes_d
  ltime_barrier = ltime_barrier_d
  luse_rttov    = luse_rttov_d
  luse_radarfwo = luse_radarfwo_d

  hstart        = hstart_d  
  hstop         = hstop_d    
  hincmxt       = hincmxt_d   
  hincmxu       = hincmxu_d   
  dt            = dt_d

  leps          = leps_d
  lphys         = lphys_d
  lsppt         = lsppt_d
  ldiagnos      = ldiagnos_d
  ldfi          = ldfi_d
  luseobs       = luseobs_d
  itype_calendar= itype_calendar_d
  ldump_ascii   = ldump_ascii_d
  lreproduce    = lreproduce_d
  lreorder      = lreorder_d
  lartif_data   = lartif_data_d
  lperi_x         = lperi_x_d     
  lperi_y         = lperi_y_d     
  l2dim         = l2dim_d
  lroutine      = lroutine_d
  llm           = llm_d
  l_cosmo_art   = l_cosmo_art_d
  l_pollen      = l_pollen_d
  ltraj         = ltraj_d
  idbg_level    = idbg_level_d
  itype_timing  = itype_timing_d

  ldebug_dyn    = ldebug_dyn_d
  ldebug_gsp    = ldebug_gsp_d
  ldebug_rad    = ldebug_rad_d
  ldebug_tur    = ldebug_tur_d
  ldebug_con    = ldebug_con_d
  ldebug_soi    = ldebug_soi_d
  ldebug_io     = ldebug_io_d
  ldebug_mpe    = ldebug_mpe_d
  ldebug_dia    = ldebug_dia_d
  ldebug_art    = ldebug_art_d
  ldebug_ass    = ldebug_ass_d
  ldebug_lhn    = ldebug_lhn_d
  lprintdeb_all = lprintdeb_all_d
  linit_fields  = linit_fields_d

  ydate_ini     = ydate_ini_d 
  ydate_end     = ydate_end_d 
  ydate_bd      = ydate_bd_d  

!------------------------------------------------------------------------------
!- Section 3: Input of the namelist values
!------------------------------------------------------------------------------

  READ (nuin, runctl, IOSTAT=iz_err)
ENDIF

IF (nproc > 1) THEN
  ! distribute error status to all processors
  CALL distribute_values  (iz_err, 1, 0, imp_integers,  icomm_world, ierr)
ENDIF

IF (iz_err /= 0) THEN
  ierrstat = -1
  RETURN
ENDIF

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 4: Check values for errors and consistency
!------------------------------------------------------------------------------

  ! Check whether the values for start and end of the forecast are
  ! given in hours and calculate the values in time steps
  IF ( hstop /= hstop_d ) THEN
    nstop = NINT(hstop * 3600.0_wp / dt)
  ELSEIF (nstop /= nstop_d) THEN
    hstop =  nstop * dt / 3600.0_wp
  ENDIF

  ! this could now be done after the distribution, but it is ok here
  nstart    = NINT(hstart * 3600.0_wp /dt)

  ! Check whether the values for the increment of "nullifying" tmin, tmax, vbmax
  ! are given in multiples of 0.25 hours and calculate the value in time steps
  IF ( hincmxu /= hincmxu_d) THEN
    IF ( ABS(REAL(NINT(hincmxu), wp) - hincmxu) > 1.0E-5_wp) THEN
      ! then it is not a full hour, only allow 0.25 and 0.5
      IF ( (hincmxu /= 0.50_wp) .AND. (hincmxu /= 0.25_wp) ) THEN
        PRINT *, 'ERROR: *** This is not a valid hincmxu: ', hincmxu, '   ***'
        PRINT *, '       *** only values = n.0 / 0.5 / 0.25 are allowed   ***'
        ierrstat = 1002
      ENDIF
    ENDIF
  ENDIF

  ! Calculate last and next hour and time step
  IF (hstart == 0) THEN
    ! no restart run; re-initialize after first step
    hlastmxu = 0.0_wp
    hnextmxu = 0.0_wp
    nlastmxu = 0
    nnextmxu = 0
  ELSE
    ! endless loop for finding the last hour (for restart runs)
    hlastmxu = 0.0_wp
    endless_u: DO
!US   IF ( (hlastmxu <= hstart) .AND. (hstart < hlastmxu + hincmxu) ) THEN
      IF ( (hlastmxu <= hstart) .AND. (hstart <= hlastmxu + hincmxu) ) THEN
        EXIT endless_u
      ENDIF
      hlastmxu = hlastmxu + hincmxu
    ENDDO endless_u
    hnextmxu = hlastmxu + hincmxu
    nlastmxu = NINT (hlastmxu * 3600.0_wp / dt)
    nnextmxu = NINT (hnextmxu * 3600.0_wp / dt)
  ENDIF

  ! And the same for the temperatures
  IF ( hincmxt /= hincmxt_d) THEN
    IF ( ABS(REAL(NINT(hincmxt), wp) - hincmxt) > 1.0E-5_wp) THEN
      ! then it is not a full hour, only allow 0.25 and 0.5
      IF ( (hincmxt /= 0.50_wp) .AND. (hincmxt /= 0.25_wp) ) THEN
        PRINT *, 'ERROR: *** This is not a valid hincmxt: ', hincmxt, '   ***'
        PRINT *, '       *** only values = n.0 / 0.5 / 0.25 are allowed   ***'
        ierrstat = 1002
      ENDIF
    ENDIF
  ENDIF

  ! Calculate last and next hour and time step
  ! endless loop for finding the last hour (for restart runs)
  IF (hstart == 0) THEN
    ! no restart run; re-initialize after first step
    hlastmxt = 0.0_wp
    hnextmxt = 0.0_wp
    nlastmxt = 0
    nnextmxt = 0
  ELSE
    hlastmxt = 0.0_wp
    endless_t: DO
!US   IF ( (hlastmxt <= hstart) .AND. (hstart < hlastmxt + hincmxt) ) THEN
      IF ( (hlastmxt <= hstart) .AND. (hstart <= hlastmxt + hincmxt) ) THEN
        EXIT endless_t
      ENDIF
      hlastmxt = hlastmxt + hincmxt
    ENDDO endless_t
    hnextmxt = hlastmxt + hincmxt
    nlastmxt = NINT (hlastmxt * 3600.0_wp / dt)
    nnextmxt = NINT (hnextmxt * 3600.0_wp / dt)
  ENDIF

#ifndef MESSY
  ! Check whether the start date has been set, because this
  ! is needed:
  IF ( ydate_ini == ydate_ini_d ) THEN
    IF (lartif_data) THEN
      ! From Version 4.24 on the new date format is used
      ydate_ini = '20040321000000'
      lmmss = .TRUE.
    ELSE
      PRINT *,' ERROR   ***  ydate_ini not set ***'
      PRINT *,'         ***  Please specify ydate_ini in the format YYYYMMDDHH  ***' 
      ierrstat = 1025
    ENDIF
  ELSE
    ! Check, whether 10 or 14 digits are used for the date format
    ! NOTE: lmmss must be distributed to other PEs
    IF     (LEN_TRIM(ydate_ini) == 10) THEN
      ydate_ini(11:14) = '0000'
      lmmss = .FALSE.
      PRINT *, ' *** NOTE: Old 10 digit date format is used'
    ELSEIF (LEN_TRIM(ydate_ini) == 14) THEN
      lmmss = .TRUE.
      PRINT *, ' *** NOTE: New 14 digit date format is used'
    ELSE
      PRINT *, ' *** ERROR: Wrong number of digits for ydate_ini! *** '
      PRINT *, ' ***        Must be 10 or 14, but are ', LEN_TRIM(ydate_ini)
      ierrstat = 1025
    ENDIF
  ENDIF

  ! Check whether a date is given for the start of the forecast for the
  ! boundary fields
  IF ( ydate_bd == ydate_bd_d ) THEN
    ydate_bd = ydate_ini
  ELSE
    ! Check, whether 10 or 14 digits are used for the date format
    IF     (LEN_TRIM(ydate_bd) == 10) THEN
      ydate_bd(11:14) = '0000'
    ELSEIF (LEN_TRIM(ydate_bd) /= 14) THEN
      PRINT *, ' *** ERROR: Wrong number of digits for ydate_bd!  *** '
      PRINT *, ' ***        Must be 10 or 14, but are ', LEN_TRIM(ydate_bd)
      ierrstat = 1025
    ENDIF
  ENDIF

  IF ( ydate_end /= ydate_end_d ) THEN
    ! compute total number of timesteps necessary to do the whole simulation
    ! format to read the year has been changed from "2X,I2" to "4I"
    !    this is, what diff_minutes expects!
    IF (LEN_TRIM(ydate_end) == 10) THEN
      ydate_end(11:14) = '0000'
    ELSEIF (LEN_TRIM(ydate_end) /= 14) THEN
      PRINT *, ' *** ERROR: Wrong number of digits for ydate_end!  *** '
      PRINT *, ' ***        Must be 10 or 14, but are ', LEN_TRIM(ydate_end)
      ierrstat = 1025

      ! but set the date correct, otherwise the next READ might fail
      ydate_end(11:14) = '0000'
    ENDIF

    READ( ydate_ini,'(I4,5I2)' ) iniyy, inimm, inidd, inihh, inimi, iniss
    READ( ydate_end,'(I4,5I2)' ) indyy, indmm, inddd, indhh, indmi, indss
    CALL diff_minutes ( iniyy, inimm, inidd, inihh, 0,                 &
                        indyy, indmm, inddd, indhh, 0,                 &
                        itype_calendar, imindif, ierrf )
    nfinalstop =  NINT( (REAL(imindif, wp) * 60.0_wp +         &
                        (REAL(indss, wp)-REAL(iniss, wp)))/ dt , iintegers )
  ELSE
    ! no end date is given; then the end of the whole forecast is given
    ! by hstop / nstop
    nfinalstop = nstop
  ENDIF
#endif

  ! Check whether type of calendar is in the correct range
  IF ( (itype_calendar < 0) .OR. (itype_calendar > 2) ) THEN
    PRINT *,' ERROR   ***  Wrong value for itype_calendar = ', itype_calendar, ' ***'
    PRINT *,'         ***  must be >= 0 and <= 2   ***' 
    ierrstat = 1002
  ENDIF

  ! Check whether total number of PEs is correct
  IF (nprocio > 0) THEN
    IF ( nprocx * nprocy + nprocio /= nproc ) THEN
      PRINT *,' ERROR    *** Wrong number of PEs for asnychronous IO *** '
      PRINT *,'          *** ',nprocx,' * ',nprocy,' + ',nprocio,' /= ',nproc
      ierrstat = 1002
    ENDIF
  ELSEIF (num_asynio_comm*num_iope_percomm > 0) THEN
    IF ( nprocx * nprocy + num_asynio_comm*num_iope_percomm /= nproc ) THEN
      PRINT *,' ERROR    *** Wrong number of PEs *** '
      PRINT *,'          *** ',nprocx,' * ',nprocy,' + ',num_asynio_comm*num_iope_percomm,' /= ',nproc
      ierrstat = 1002
    ENDIF
  ELSE
    IF ( nprocx * nprocy /= nproc ) THEN
      PRINT *,' ERROR    *** Wrong number of PEs *** '
      PRINT *,'          *** ',nprocx,' * ',nprocy,' /= ',nproc
      ierrstat = 1002
    ENDIF
  ENDIF
#ifndef PNETCDF
  IF (num_iope_percomm > 1 ) THEN
    PRINT *,'ERROR *** If parallel netcdf is not enabled, more than one IO PE per IO communicator is not allow'
    PRINT *,'      *** recompile with PNETCDF to use parallel netcdf'
    ierrstat = 1002
  ENDIF
#endif
#ifndef NETCDF
  IF (num_iope_percomm > 0 .OR. num_asynio_comm > 0) THEN
    PRINT *,'ERROR *** Asynchronous netcdf not available if not compile with NETCDF'
    ierrstat = 1002
  ENDIF
#endif

  IF ( num_iope_percomm > 0 .AND. nprocio > 0 ) THEN
    PRINT *,' ERROR     *** num_iope_percomm and nprocio can not be both >0 ***'
    ierrstat = 1002
  ENDIF

  ! Check for periodic boundary conditions, metric terms and 2D-version
  IF (lartif_data .EQV. .FALSE.) THEN
    IF (lperi_x .EQV. .TRUE.) THEN
      PRINT *,' ERROR    *** lperi_x = .TRUE. only if lartif_data = .TRUE. *** '
      ierrstat = 1002
    ENDIF
    IF (lperi_y .EQV. .TRUE.) THEN
      PRINT *,' ERROR    *** lperi_y = .TRUE. only if lartif_data = .TRUE. *** '
      ierrstat = 1002
    ENDIF
    IF (l2dim .EQV. .TRUE.) THEN
      PRINT *,' ERROR    *** l2dim = .TRUE. only if lartif_data = .TRUE. *** '
      ierrstat = 1002
    ENDIF
  ENDIF

  ! Check the dimension in case of 2dimensional model runs. It is always
  ! assumed that the solution is along the x-axis (in i-direction).
  IF (l2dim) THEN
    IF ( je_tot /= 2*nboundlines+1) THEN
      PRINT *,' ERROR    *** je_tot has to be ', 2*nboundlines+1,  &
              ' for 2-dimensional runs *** '
      ierrstat = 1002
    ENDIF
    IF ( nprocy > 1 ) THEN
      PRINT *,' ERROR    *** nprocy has to be 1 for 2-dimensional runs *** '
      ierrstat = 1002
    ENDIF
    IF (lperi_y .EQV. .TRUE.) THEN
      PRINT *,' ERROR    *** lperi_y = .TRUE. and l2dim = .TRUE. not possible! *** '
      PRINT *,'          *** Set lperi_y = .FALSE. for 2-dimensional runs!     *** '
      ierrstat = 1002
    ENDIF
  ENDIF

  ! Check ie_tot, je_tot for periodic BCs in parallel runs. Have to be >= 3*nboundlines,
  !   otherwise the periodic MPI exchange does not work correctly.
  IF (num_compute > 1) THEN
    IF (lperi_x .EQV. .TRUE. .and. ie_tot < 3*nboundlines) THEN
      PRINT *,' ERROR    *** ie_tot too small for parallel run with MPI exchange *** '
      PRINT *,'          *** and lperi_x = .TRUE.! ie_tot has to be >= ',3*nboundlines,', *** '
      PRINT *,'          *** or use only one processor! *** '
      ierrstat = 1002
    ENDIF
    IF (lperi_y .EQV. .TRUE. .and. je_tot < 3*nboundlines) THEN
      PRINT *,' ERROR    *** je_tot too small for parallel run with MPI exchange *** '
      PRINT *,'          *** and lperi_y = .TRUE.! je_tot has to be >= ',3*nboundlines,', *** '
      PRINT *,'          *** or use only one processor! *** '
      ierrstat = 1002
    ENDIF
  ENDIF

  ! Check whether nboundlines >= 2
  IF ( nboundlines < 2 ) THEN
    PRINT *,' ERROR    *** nboundlines has to be >= 2 *** '
    PRINT *,'          ***    nboundlines = ',nboundlines,' *** '
    ierrstat = 1003
  ENDIF

  ! Check whether type of communication is in the correct range
  IF ( (ncomm_type < 1) .OR. (ncomm_type > 3) ) THEN
    PRINT *,' ERROR    *** unknown type of communication type ***'
    PRINT *,'          ***   (1 <= ncomm_type <= 3), but is ', ncomm_type,' ***'
    ierrstat = 1004
  ENDIF

  ! Check whether type of timing is in the correct range
  IF ( (itype_timing < 0) .OR. (itype_timing > 4) ) THEN
    PRINT *,'WARNING  ***  Wrong value for itype_timing = ', itype_timing, ' ***'
    PRINT *,'         ***  must be >= 0 and <= 4   ***' 
    PRINT *,'WARNING  ***  Timing is switched off  ***'
  ENDIF

  ! Check whether the use of additional barriers for determining the
  ! load-imbalance makes sense:
  IF (ltime_barrier .AND. nproc == 1) THEN
    PRINT *,'WARNING  ***  ltime_barrier = .true.          ***'
    PRINT *,'         ***  only makes sense if nproc > 1   ***' 
    PRINT *,'WARNING  ***  ltime_barrier is set to .false. ***'
    ltime_barrier = .FALSE.
  END IF

  ! Check if ltraj is used in combination of either lperi_x or lperi_y
  IF (ltraj .AND. (lperi_x .OR. lperi_y)) THEN
    PRINT *,'WARNING  ***  ltraj is used in combination with lperi_x/y  ***'
    PRINT *,'         ***  but the trajectory "cycling" is not supported!!!   ***'
  ENDIF

#ifndef NUDGING
  IF (luseobs) THEN
    PRINT *,' ERROR  *** luseobs is set, but model is not compiled for NUDGING ***'
    ierrstat = 1004
  ENDIF
#endif

#ifdef MESSY
  IF (luseobs) THEN
    PRINT *,' ERROR  *** Model is compiled for MESSY, therefore NUDGING can not be used ***'
    ierrstat = 1004
  ENDIF

  IF (ldfi) THEN
    PRINT *,' ERROR  *** Model is compiled for MESSY, therefore DFI can not be used ***'
    ierrstat = 1004
  ENDIF
#endif

#if !defined RTTOV7 && !defined RTTOV9 && !defined RTTOV10
  IF (luse_rttov) THEN
    PRINT *,' ERROR    *** luse_rttov is set, but model is not compiled for RTTOV model ***'
    ierrstat = 1004
  ENDIF
#endif

#ifndef RADARFWO
  IF (luse_radarfwo) THEN
    PRINT *,' ERROR    *** luse_radarfwo is set, but model is *** '
    PRINT *,' ERROR    *** NOT compiled for radar forward operator ***'
    ierrstat = 1004
  ENDIF
#endif

#ifndef POLLEN
  IF (l_pollen) THEN
    PRINT *,' ERROR    *** l_pollen is set, but model ***'
    PRINT *,'          *** is not compiled for POLLEN ***'
    ierrstat = 1004
  ENDIF
#endif

#ifndef COSMOART
  IF (l_cosmo_art) THEN
    PRINT *,' ERROR    *** l_cosmo_art is set, but model ***'
    PRINT *,'          *** is not compiled for COSMO_ART ***'
    ierrstat = 1004
  ENDIF
#endif

ENDIF

!------------------------------------------------------------------------------
!- Section 5: Distribute variables to all nodes
!------------------------------------------------------------------------------

IF (nproc > 1) THEN

  IF (my_world_id == 0) THEN
    intbuf  ( 1) = nstart
    intbuf  ( 2) = nstop
    intbuf  ( 3) = nprocx
    intbuf  ( 4) = nprocy
    intbuf  ( 5) = nprocio
    intbuf  ( 6) = nboundlines
    intbuf  ( 7) = ncomm_type
    intbuf  ( 8) = idbg_level
    intbuf  ( 9) = nlastmxu
    intbuf  (10) = nnextmxu
    intbuf  (11) = nlastmxt
    intbuf  (12) = nnextmxt
    intbuf  (13) = itype_timing
    intbuf  (14) = itype_calendar
    intbuf  (15) = nfinalstop
    intbuf  (16) = num_asynio_comm
    intbuf  (17) = num_iope_percomm
    intbuf  (18) = nproma
    intbuf  (19) = nblock
    realbuf ( 1) = dt
    realbuf ( 2) = hstart
    realbuf ( 3) = hlastmxu
    realbuf ( 4) = hnextmxu
    realbuf ( 5) = hincmxu
    realbuf ( 6) = hlastmxt
    realbuf ( 7) = hnextmxt
    realbuf ( 8) = hincmxt
    realbuf ( 9) = hstop
    logbuf  ( 1) = lphys
    logbuf  ( 2) = ldiagnos
    logbuf  ( 3) = ldfi
    logbuf  ( 4) = luseobs
    logbuf  ( 8) = lreproduce
    logbuf  ( 9) = lartif_data
    logbuf  (10) = lperi_x
    logbuf  (11) = l2dim
    logbuf  (13) = llm
    logbuf  (14) = lreorder
    logbuf  (15) = ldatatypes
    logbuf  (16) = ltime_barrier
    logbuf  (17) = luse_rttov
    logbuf  (18) = luse_radarfwo
    logbuf  (19) = leps
    logbuf  (20) = ldump_ascii
    logbuf  (21) = ldebug_dyn
    logbuf  (22) = ldebug_gsp
    logbuf  (23) = ldebug_rad
    logbuf  (24) = ldebug_tur
    logbuf  (25) = ldebug_con
    logbuf  (26) = ldebug_soi
    logbuf  (27) = ldebug_io
    logbuf  (28) = ldebug_mpe
    logbuf  (29) = ldebug_dia
    logbuf  (30) = ldebug_art
    logbuf  (31) = ldebug_ass
    logbuf  (32) = ldebug_lhn
    logbuf  (33) = lprintdeb_all
    logbuf  (34) = linit_fields
    logbuf  (35) = l_cosmo_art
    logbuf  (36) = l_pollen
    logbuf  (37) = lperi_y
    logbuf  (38) = lmmss
    logbuf  (39) = lroutine
    logbuf  (40) = ltraj
    logbuf  (41) = lsppt
    charbuf ( 1) = ydate_ini
    charbuf ( 2) = ydate_end
    charbuf ( 3) = ydate_bd
  ENDIF

  CALL distribute_values (intbuf, 19, 0, imp_integers,  icomm_world, ierr)
  CALL distribute_values (realbuf, 9, 0, imp_reals,     icomm_world, ierr)
  CALL distribute_values (logbuf, 41, 0, imp_logical,   icomm_world, ierr)
  CALL distribute_values (charbuf, 3, 0, imp_character, icomm_world, ierr)

  IF (my_world_id /= 0) THEN
    nstart       = intbuf  ( 1)
    nstop        = intbuf  ( 2)
    nprocx       = intbuf  ( 3)
    nprocy       = intbuf  ( 4)
    nprocio      = intbuf  ( 5)
    nboundlines  = intbuf  ( 6)
    ncomm_type   = intbuf  ( 7)
    idbg_level   = intbuf  ( 8)
    nlastmxu     = intbuf  ( 9)
    nnextmxu     = intbuf  (10)
    nlastmxt     = intbuf  (11)
    nnextmxt     = intbuf  (12)
    itype_timing = intbuf  (13)
    itype_calendar=intbuf  (14)
    nfinalstop   = intbuf  (15)
    num_asynio_comm   = intbuf  (16)
    num_iope_percomm  = intbuf  (17)
    nproma       = intbuf  (18)
    nblock       = intbuf  (19)
    dt           = realbuf ( 1)
    hstart       = realbuf ( 2)
    hlastmxu     = realbuf ( 3)
    hnextmxu     = realbuf ( 4)
    hincmxu      = realbuf ( 5)
    hlastmxt     = realbuf ( 6)
    hnextmxt     = realbuf ( 7)
    hincmxt      = realbuf ( 8)
    hstop        = realbuf ( 9)
    lphys        = logbuf  ( 1)
    ldiagnos     = logbuf  ( 2)
    ldfi         = logbuf  ( 3)
    luseobs      = logbuf  ( 4)
    lreproduce   = logbuf  ( 8)
    lartif_data  = logbuf  ( 9)
    lperi_x      = logbuf  (10)
    l2dim        = logbuf  (11)
    llm          = logbuf  (13)
    lreorder     = logbuf  (14)
    ldatatypes   = logbuf  (15)
    ltime_barrier= logbuf  (16)
    luse_rttov   = logbuf  (17)
    luse_radarfwo= logbuf  (18)
    leps         = logbuf  (19)
    ldump_ascii  = logbuf  (20)
    ldebug_dyn   = logbuf  (21)
    ldebug_gsp   = logbuf  (22)
    ldebug_rad   = logbuf  (23)
    ldebug_tur   = logbuf  (24)
    ldebug_con   = logbuf  (25)
    ldebug_soi   = logbuf  (26)
    ldebug_io    = logbuf  (27)
    ldebug_mpe   = logbuf  (28)
    ldebug_dia   = logbuf  (29)
    ldebug_art   = logbuf  (30)
    ldebug_ass   = logbuf  (31)
    ldebug_lhn   = logbuf  (32)
    lprintdeb_all= logbuf  (33)
    linit_fields = logbuf  (34)
    l_cosmo_art  = logbuf  (35)
    l_pollen     = logbuf  (36)
    lperi_y      = logbuf  (37)
    lmmss        = logbuf  (38)
    lroutine     = logbuf  (39)
    ltraj        = logbuf  (40)
    lsppt        = logbuf  (41)
    ydate_ini(1:14) = charbuf ( 1)(1:14)
    ydate_end(1:14) = charbuf ( 2)(1:14)
    ydate_bd (1:14) = charbuf ( 3)(1:14)
  ENDIF

ENDIF

! Set ltime depending on itype_timing
IF (lclock .EQV. .FALSE.) THEN
  ! If no system clock is present, ltime has to be .FALSE.
  itype_timing = 0
  ltime = .FALSE.
  PRINT *,'  WARNING  ***  NO SYSTEM CLOCK PRESENT ***'
  PRINT *,'           ***  Timing is switched off  ***'
ELSE
  IF ( (itype_timing > 0) .AND. (itype_timing <= 4) ) THEN
    ltime = .TRUE.
  ELSE
    ltime = .FALSE.
  ENDIF
ENDIF

! Determine number of compute PEs and number of IO PEs
num_compute = nprocx * nprocy
nc_asyn_io = num_asynio_comm * num_iope_percomm

!------------------------------------------------------------------------------
!- Section 6: Output of the namelist variables and their default values
!------------------------------------------------------------------------------

IF (my_world_id == 0) THEN

  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(A23)') '0     NAMELIST:  runctl'
  WRITE (nuspecif, '(A23)') '      -----------------'
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(T7,A,T33,A,T51,A,T70,A)') 'Variable', 'Actual Value',   &
                                               'Default Value', 'Format'

  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                        'hstart  ',hstart  ,hstart_d  ,' R '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                       'nstop    ',nstop    ,nstop_d  ,' I '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                              'hstop ',hstop ,hstop_d ,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                              'dt    ',dt    ,dt_d    ,' R '

  tmpdate_ini = ydate_ini
  IF (LEN_TRIM(ydate_ini) == 0) THEN
    tmpdate_ini = '-'
  END IF
  tmpdate_ini_d = ydate_ini_d
  IF (LEN_TRIM(ydate_ini_d) == 0) THEN
    tmpdate_ini_d = '-'
  END IF
  tmpdate_end = ydate_end
  IF (LEN_TRIM(ydate_end) == 0) THEN
    tmpdate_end = '-'
  END IF
  tmpdate_end_d = ydate_end_d
  IF (LEN_TRIM(ydate_end_d) == 0) THEN
    tmpdate_end_d = '-'
  END IF
  tmpdate_bd = ydate_bd
  IF (LEN_TRIM(ydate_bd) == 0) THEN
    tmpdate_bd = '-'
  END IF
  tmpdate_bd_d = ydate_bd_d
  IF (LEN_TRIM(ydate_bd_d) == 0) THEN
    tmpdate_bd_d = '-'
  END IF

  IF (lmmss) THEN
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_ini ' ,tmpdate_ini(1:14)  ,tmpdate_ini_d(1:14),'C*14'
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_end ' ,tmpdate_end(1:14)  ,tmpdate_end_d(1:14),'C*14'
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_bd  ' ,tmpdate_bd(1:14)   ,tmpdate_bd_d(1:14) ,'C*14'
  ELSE
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_ini ' ,tmpdate_ini(1:10)  ,tmpdate_ini_d(1:10),'C*10'
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_end ' ,tmpdate_end(1:10)  ,tmpdate_end_d(1:10),'C*10'
    WRITE (nuspecif, '(T8,A,T33,  A  ,T52,  A  ,T71,A4)')                    &
                     'ydate_bd  ' ,tmpdate_bd(1:10)   ,tmpdate_bd_d(1:10) ,'C*10'
  ENDIF
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                    'itype_calendar', itype_calendar, itype_calendar_d,' I '

  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'hincmxt',hincmxt,hincmxt_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'hincmxu',hincmxu,hincmxu_d,' R '

  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                        'leps', leps, leps_d          ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                        'lphys',  lphys, lphys_d      ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'lsppt',     lsppt,    lsppt_d         ,' L '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                      'nproma   ',nproma   ,nproma_d  ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                      'nblock   ',nblock   ,nblock_d  ,' I '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldiagnos',  ldiagnos, ldiagnos_d      ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldfi',      ldfi,     ldfi_d          ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'luseobs',   luseobs,  luseobs_d       ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'luse_rttov', luse_rttov, luse_rttov_d ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                      'luse_radarfwo', luse_radarfwo, luse_radarfwo_d ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                           'l_cosmo_art', l_cosmo_art,  l_cosmo_art_d ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                    'l_pollen', l_pollen,  l_pollen_d ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                    'ltraj',      ltraj,      ltraj_d ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                             'ldump_ascii', ldump_ascii, ldump_ascii_d,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                              'lreproduce', lreproduce, lreproduce_d  ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                              'lreorder  ', lreorder  , lreorder_d    ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                           'lartif_data',lartif_data, lartif_data_d   ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                             'lperi_x',lperi_x, lperi_x_d   ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                             'lperi_y',lperi_y, lperi_y_d   ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                             'l2dim',l2dim, l2dim_d   ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                            'lroutine',   lroutine,  lroutine_d       ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                                           'llm',   llm,  llm_d       ,' L '

  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                 'nprocx     ',nprocx     ,nprocx_d   ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                 'nprocy     ',nprocy     ,nprocy_d   ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                 'nprocio    ',nprocio    ,nprocio_d  ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                  'num_asynio_comm',num_asynio_comm , num_asynio_comm ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                'num_iope_percomm',num_iope_percomm, num_iope_percomm ,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                            'nboundlines', nboundlines, nboundlines_d, ' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                               'ncomm_type', ncomm_type, ncomm_type_d, ' I '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                              'ldatatypes',ldatatypes, ldatatypes_d   ,' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                        'ltime_barrier',ltime_barrier, ltime_barrier_d,' L '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                          'itype_timing', itype_timing, itype_timing_d,' I '
  WRITE (nuspecif, '(T8,A,T33,I12  ,T52,I12  ,T71,A3)')                      &
                                'idbg_level', idbg_level, idbg_level_d,' I '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_dyn', ldebug_dyn, ldebug_dyn_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_gsp', ldebug_gsp, ldebug_gsp_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_rad', ldebug_rad, ldebug_rad_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_tur', ldebug_tur, ldebug_tur_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_con', ldebug_con, ldebug_con_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_soi', ldebug_soi, ldebug_soi_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_io',  ldebug_io,  ldebug_io_d,  ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                            'ldebug_mpe',  ldebug_mpe,  ldebug_mpe_d,  ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_dia', ldebug_dia, ldebug_dia_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_art', ldebug_art, ldebug_art_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_ass', ldebug_ass, ldebug_ass_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                               'ldebug_lhn', ldebug_lhn, ldebug_lhn_d, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                        'lprintdeb_all', lprintdeb_all, lprintdeb_all, ' L '
  WRITE (nuspecif, '(T8,A,T33,L12  ,T52,L12  ,T71,A3)')                      &
                        'linit_fields ', linit_fields , linit_fields , ' L '
  WRITE (nuspecif, '(A2)')  '  '

ENDIF

!------------------------------------------------------------------------------
!- End of the Subroutine
!------------------------------------------------------------------------------

END SUBROUTINE input_runctl

!==============================================================================
#endif
!==============================================================================
!+ Module procedure in "setup" for the input of NAMELIST tuning
!------------------------------------------------------------------------------

SUBROUTINE input_tuning (nuspecif, nuin, ierrstat)

!------------------------------------------------------------------------------
!
! Description:
!   This subroutine organizes the input of the NAMELIST-group tuning.
!   The group tuning contains variables that can be varied to change the
!   behaviour of the model.
!
!------------------------------------------------------------------------------

! Subroutine / Function arguments
  INTEGER   (KIND=iintegers),   INTENT (IN)      ::        &
    nuspecif,     & ! Unit number for protocolling the task
    nuin            ! Unit number for Namelist INPUT file

  INTEGER   (KIND=iintegers),   INTENT (OUT)   ::        &
    ierrstat        ! error status variable

!------------------------------------------------------------------------------

! Variables for default values
  REAL (KIND=wp)             ::       &
    crsmin_d,     & ! minimum value of stomatal resistance (used by the BATS
                    ! approache for vegetation transpiration, itype_trvg=2)
    rat_lam_d,    & ! ratio of laminar scaling factors for vapour and heat

    tkesmot_d,    & ! time smoothing factor for TKE and diffusion coefficients
    wichfakt_d,   & ! vertical smoothing factor for explicit diffusion tendencies
    securi_d,     & ! security factor for maximal diffusion coefficients
    tkhmin_d,     & ! minimal diffusion coefficients for heat
    tkmmin_d,     & ! minimal diffusion coefficients for momentum
    rat_sea_d,    & ! ratio of laminar scaling factors for heat over sea and land
    rat_can_d,    & ! ratio of canopy height over z0m
    c_lnd_d,      & ! maximum roughness length for scalars over land
    c_sea_d,      & ! maximum roughness length for scalars over see
    c_soil_d,     & ! surface area index of (evaporative) soil surfaces
    e_surf_d,     & ! exponent to get the effective surface area
    rlam_mom_d,   & ! scaling factor of the laminar boundary layer for momontum
    rlam_heat_d,  & ! scaling factor of the laminar boundary layer for heat
    pat_len_d,    & ! lenth scale of subscale surface patterns over land
    z0m_dia_d,    & ! roughness length of a typical synoptical station
    tur_len_d,    & ! maximal turbulent length scale
    a_heat_d,     & ! factor for turbulent heat transport
    a_mom_d,      & ! factor for turbulent momentum transport
    d_heat_d,     & ! factor for turbulent heat dissipation
    d_mom_d,      & ! factor for turbulent momentum dissipation
    c_diff_d,     & ! factor for turbulent diffusion of TKE
    a_hshr_d,     & ! factor for separate horizontal shear production
    a_stab_d,     & ! factor for stability correction of turbulent length scale

    clc_diag_d,   & ! cloud cover at saturation in statistical cloud diagnostic
    q_crit_d,     & ! critical value for normalized over-saturation
    qi0_d,        & ! cloud ice threshold for autoconversion
    qc0_d,        & ! cloud water threshold for autoconversion
    v0snow_d,     & ! factor in the terminal velocity for snow
    mu_rain_d,    & !
    rain_n0_factor_d, & !
    cloud_num_d,  & ! cloud droplet number concentration
    entr_sc_d,    & ! mean entrainment rate for shallow convection
    thick_sc_d,   & ! thickness limit for convective clouds to be "shallow" (in Pa)
    gkdrag_d,     & ! gravity wave drag constant
    gkwake_d        ! low level wake drag constant

  INTEGER (KIND=iintegers)   :: ierr, iz_err

  NAMELIST /TUNING/ rlam_mom, rlam_heat, rat_sea, rat_lam, rat_can,           &
                    z0m_dia, c_lnd, c_sea, c_soil, e_surf, tur_len, pat_len,  &
                    a_heat, a_mom, d_heat, d_mom, c_diff, a_hshr, a_stab,     &
                    clc_diag, q_crit,                                         &
                    tkhmin, tkmmin, tkesmot, wichfakt, securi, qi0, qc0,      &
                    crsmin, gkdrag, gkwake, mu_rain, cloud_num, entr_sc,      &
                    thick_sc, v0snow, rain_n0_factor

!------------------------------------------------------------------------------
!- End of header -
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Begin SUBROUTINE input_tuning
!------------------------------------------------------------------------------

ierrstat = 0_iintegers
iz_err   = 0_iintegers

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 1: Initialize the default variables
!------------------------------------------------------------------------------

  ! Initial values taken from data_turbulence:
  rlam_mom_d   = rlam_mom
  rlam_heat_d  = rlam_heat
  rat_lam_d    = rat_lam
  rat_sea_d    = rat_sea
  rat_can_d    = rat_can
  z0m_dia_d    = z0m_dia
  c_lnd_d      = c_lnd
  c_sea_d      = c_sea
  c_soil_d     = c_soil
  e_surf_d     = e_surf
  tur_len_d    = tur_len
  pat_len_d    = pat_len
  a_heat_d     = a_heat
  a_mom_d      = a_mom
  d_heat_d     = d_heat
  d_mom_d      = d_mom
  c_diff_d     = c_diff
  a_hshr_d     = a_hshr
  a_stab_d     = a_stab
  clc_diag_d   = clc_diag
  q_crit_d     = q_crit
  tkhmin_d     = tkhmin
  tkmmin_d     = tkmmin
  tkesmot_d    = tkesmot
  wichfakt_d   = wichfakt
  securi_d     = securi
  crsmin_d     = crsmin
  gkdrag_d     = gkdrag
  gkwake_d     = gkwake
  mu_rain_d    = mu_rain
  rain_n0_factor_d = rain_n0_factor
  v0snow_d     = v0snow
  cloud_num_d  = cloud_num
  entr_sc_d    = entr_sc
  thick_sc_d   = thick_sc

  ! No initial values available:
  qc0_d        = 0.0_wp  ! value taken from src-gscp
  qi0_d        = 0.0_wp  ! value taken from src-gscp

!------------------------------------------------------------------------------
!- Section 2: Initialize the remaining variables with defaults
!------------------------------------------------------------------------------

  qc0            = qc0_d
  qi0            = qi0_d

!------------------------------------------------------------------------------
!- Section 3: Input of the namelist values
!------------------------------------------------------------------------------

  READ (nuin, tuning, IOSTAT=iz_err)
ENDIF

IF (nproc > 1) THEN
  ! distribute error status to all processors
  CALL distribute_values  (iz_err, 1, 0, imp_integers,  icomm_world, ierr)
ENDIF

IF (iz_err /= 0) THEN
  ierrstat = -1
  RETURN
ENDIF

IF (my_world_id == 0) THEN

!------------------------------------------------------------------------------
!- Section 4: Check values for errors and consistency
!------------------------------------------------------------------------------

  ! rlam_mom
  IF (rlam_mom < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** rlam_mom must be >= 0!  actual value = ', rlam_mom, ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (rlam_mom > 1.0_wp) THEN
      PRINT *, ' WARNING  *** rlam_mom = ', rlam_mom, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 1 ] *** '
    ENDIF
  ENDIF

  ! rlam_heat
  IF (rlam_heat <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** rlam_heat must be > 0!  actual value = ', rlam_heat, ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (rlam_heat < 0.1_wp) .OR. (rlam_heat > 10.0_wp) ) THEN
      PRINT *, ' WARNING  *** rlam_heat = ', rlam_heat, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is ] 0.1 , 10 ] *** '
    ENDIF
  ENDIF

  ! rat_lam  
  IF (rat_lam <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** rat_lam must be > 0!  actual value = ', rat_lam  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (rat_lam  < 0.1_wp) .OR. (rat_lam   > 10.0_wp) ) THEN
      PRINT *, ' WARNING  *** rat_lam = ', rat_lam, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is ] 0.1 , 10 ] *** '
    ENDIF
  ENDIF

  ! rat_can  
  IF (rat_can < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** rat_can must be >= 0!  actual value = ', rat_can  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (rat_can > 10.0_wp) THEN
      PRINT *, ' WARNING  *** rat_can = ', rat_can, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 10 ] *** '
    ENDIF
  ENDIF

  ! rat_sea  
  IF (rat_sea <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** rat_sea must be > 0!  actual value = ', rat_sea  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (rat_sea  < 1.0_wp) .OR. (rat_sea > 100.0_wp) ) THEN
      PRINT *, ' WARNING  *** rat_sea = ', rat_sea, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 1 , 100 ] *** '
    ENDIF
  ENDIF

  ! z0m_dia  
  IF (z0m_dia <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** z0m_dia must be > 0!  actual value = ', z0m_dia  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (z0m_dia  < 0.001_wp) .OR. (z0m_dia > 10.0_wp) ) THEN
      PRINT *, ' WARNING  *** z0m_dia = ', z0m_dia, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.001 , 10 ] *** '
    ENDIF
  ENDIF

  ! c_lnd    
  IF (c_lnd < 1.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** c_lnd   must be >= 1.0!  actual value = ', c_lnd    , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (c_lnd > 10.0_wp) THEN
      PRINT *, ' WARNING  *** c_lnd   = ', c_lnd  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 1 , 10 ] *** '
    ENDIF
  ENDIF

  ! c_sea    
  IF (c_sea < 1.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** c_sea   must be >= 1.0!  actual value = ', c_sea    , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (c_sea > 10.0_wp) THEN
      PRINT *, ' WARNING  *** c_sea   = ', c_sea  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 1 , 10 ] *** '
    ENDIF
  ENDIF

  ! c_soil   
  IF (c_soil < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** c_soil  must be >= 0.0!  actual value = ', c_soil   , ' *** '
    ierrstat = 1002
  ENDIF
  IF (c_soil > c_lnd) THEN
    PRINT *, ' ERROR  *** c_soil  must be <= c_lnd!  actual value = ', c_soil   , ' *** '
    ierrstat = 1002
  ENDIF

  ! e_surf   
  IF (e_surf <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** e_surf  must be > 0.0!  actual value = ', e_surf   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (e_surf < 0.1_wp) .OR. (e_surf > 10.0_wp) ) THEN
      PRINT *, ' WARNING  *** e_surf  = ', e_surf , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.1 , 10 ] *** '
    ENDIF
  ENDIF

  ! tur_len  
  IF (tur_len <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** tur_len must be > 0!  actual value = ', tur_len  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (tur_len  < 10.0_wp) .OR. (tur_len > 10000.0_wp) ) THEN
      PRINT *, ' WARNING  *** tur_len = ', tur_len, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 10 , 10000 ] *** '
    ENDIF
  ENDIF

  ! pat_len  
  IF (pat_len < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** pat_len must be >= 0!  actual value = ', pat_len  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (pat_len > 10000.0_wp) THEN
      PRINT *, ' WARNING  *** pat_len = ', pat_len, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 10000 ] *** '
    ENDIF
  ENDIF

  ! a_heat
  IF (a_heat  <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** a_heat  must be > 0!  actual value = ', a_heat   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (a_heat < 0.01_wp) .OR. (a_heat > 100.0_wp) ) THEN
      PRINT *, ' WARNING  *** a_heat  = ', a_heat , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.01 , 100 ] *** '
    ENDIF
  ENDIF

  ! a_mom
  IF (a_mom   <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** a_mom   must be > 0!  actual value = ', a_mom    , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (a_mom  < 0.01_wp) .OR. (a_mom  > 100.0_wp) ) THEN
      PRINT *, ' WARNING  *** a_mom   = ', a_mom  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.01 , 100 ] *** '
    ENDIF
  ENDIF

  ! d_heat
  IF (d_heat  <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** d_heat  must be > 0!  actual value = ', d_heat   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (d_heat < 0.01_wp) .OR. (d_heat > 100.0_wp) ) THEN
      PRINT *, ' WARNING  *** d_heat  = ', d_heat , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.01 , 100 ] *** '
    ENDIF
  ENDIF

  ! d_mom 
  IF (d_mom   <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** d_mom   must be > 0!  actual value = ', d_mom    , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (d_mom  < 0.01_wp) .OR. (d_mom  > 100.0_wp) ) THEN
      PRINT *, ' WARNING  *** d_mom   = ', d_mom  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0.01 , 100 ] *** '
    ENDIF
  ENDIF

  ! c_diff
  IF (c_diff  < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** c_diff  must be >= 0!  actual value = ', c_diff   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (c_diff > 10.0_wp) THEN
      PRINT *, ' WARNING  *** c_diff  = ', c_diff , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 10 ] *** '
    ENDIF
  ENDIF

  ! a_hshr
  IF (a_hshr  < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** a_hshr  must be >= 0!  actual value = ', a_hshr   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (a_hshr > 100.0_wp) THEN
      PRINT *, ' WARNING  *** a_hshr  = ', a_hshr , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 100 ] *** '
    ENDIF
  ENDIF

  ! a_stab
  IF (a_stab  < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** a_stab  must be >= 0!  actual value = ', a_stab   , ' *** '
    ierrstat = 1002
  END IF

  ! clc_diag
  IF (clc_diag <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** clc_diag must be > 0!  actual value = ', clc_diag , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (clc_diag >= 1.0_wp) THEN
      PRINT *, ' WARNING  *** clc_diag = ', clc_diag, ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is ] 0 , 1 [ *** '
    ENDIF
  ENDIF

  ! q_crit
  IF (q_crit  <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** q_crit  must be > 0!  actual value = ', q_crit   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (q_crit < 1.0_wp) .OR. (q_crit > 10.0_wp) ) THEN
      PRINT *, ' WARNING  *** q_crit  = ', q_crit , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 1 , 10 ] *** '
    ENDIF
  ENDIF

  ! tkhmin  
  IF (tkhmin   < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** tkhmin   must be >= 0!  actual value = ', tkhmin   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (tkhmin > 2.0_wp) THEN
      PRINT *, ' WARNING  *** tkhmin   = ', tkhmin  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 2 ] *** '
    ENDIF
  ENDIF

  ! tkhmin  
  IF (tkmmin   < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** tkmmin   must be >= 0!  actual value = ', tkmmin   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (tkmmin > 2.0_wp) THEN
      PRINT *, ' WARNING  *** tkmmin   = ', tkmmin  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 2 ] *** '
    ENDIF
  ENDIF


  ! tkesmot 
  IF (tkesmot  < 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** tkesmot  must be >= 0!  actual value = ', tkesmot  , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF (tkesmot > 2.0_wp) THEN
      PRINT *, ' WARNING  *** tkesmot  = ', tkesmot , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 0 , 2 ] *** '
    ENDIF
  ENDIF

  ! wichfakt
  IF ( (wichfakt < 0.0_wp) .OR. (wichfakt > 1.0_wp) ) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** wichfakt must be >= 0 and <= 1.0!  actual value = ', &
                                                           wichfakt , ' *** '
    ierrstat = 1002
  ENDIF

  ! securi
  IF ( (securi   <= 0.0_wp) .OR. (securi   >  0.5_wp) ) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** securi   must be > 0 and <= 0.5!  actual value = ', &
                                                           securi   , ' *** '
    ierrstat = 1002
  ENDIF

  ! crsmin  
  IF (crsmin   <= 0.0_wp) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** crsmin   must be > 0!  actual value = ', crsmin   , ' *** '
    ierrstat = 1002
  ELSE
    ! check for meaningful values
    IF ( (crsmin < 50.0_wp) .OR. (crsmin > 200.0_wp) ) THEN
      PRINT *, ' WARNING  *** crsmin   = ', crsmin  , ' is not a meaningful value!  '
      PRINT *, '          *** Best interval is [ 50 , 200 ] *** '
    ENDIF
  ENDIF

  ! qc0
  IF ( (qc0 < 0.0_wp) .OR. (qc0 > 0.01_wp) ) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** qc0   must be >= 0 and <= 0.01!  actual value = ', qc0, ' *** '
    ierrstat = 1002
  ENDIF

  ! qi0
  IF ( (qi0 < 0.0_wp) .OR. (qi0 > 0.01_wp) ) THEN
    ! check for possible values
    PRINT *, ' ERROR  *** qi0   must be >= 0 and <= 0.01!  actual value = ', qi0, ' *** '
    ierrstat = 1002
  ENDIF

  ! mu_rain
  IF ( mu_rain /= 0.0_wp .AND. mu_rain /= 0.5_wp .AND.  &
       mu_rain /= 1.0_wp .AND. mu_rain /= 1.5_wp .AND. &
       mu_rain /= 2.0_wp) THEN
    PRINT *,' ERROR    *** mu_rain not in (0.0,0.5,1.0,1.5,2.0) *** ', mu_rain
    ierrstat = 1002
    RETURN
  ENDIF

  ! v0snow
  IF ( v0snow <= 0.0_wp) THEN
    PRINT *,' ERROR    *** v0snow must be > 0!  actual value = ', v0snow, ' *** '
    ierrstat = 1002
    RETURN
  ENDIF

  ! cloud_num
  IF ( cloud_num <= 0.0_wp) THEN
    PRINT *,' ERROR    *** cloud_num must be > 0!  actual value = ', cloud_num, ' *** '
    ierrstat = 1002
    RETURN
  ENDIF

  ! entr_sc
  IF ( entr_sc < 0.0_wp ) THEN
    PRINT *,' ERROR    *** entr_sc must be >= 0!   actual value = ', entr_sc, ' *** '
    ierrstat = 1002
    RETURN
  ENDIF

  ! thick_sc
  IF ( (thick_sc < 10000.0_wp) .OR. (thick_sc > 45000.0_wp) ) THEN
    PRINT *,' ERROR    *** reasonable values: 10000.0 <= thick_sc <= 45000.0! ***'
    PRINT *,'          ***      actual value of thick_sc = ', thick_sc, '     ***'
    ierrstat = 1002
    RETURN
  ENDIF

ENDIF

!------------------------------------------------------------------------------
!- Section 5: Distribute variables to all nodes
!------------------------------------------------------------------------------

IF (nproc > 1) THEN

  IF (my_world_id == 0) THEN
    realbuf( 1) = crsmin
    realbuf( 2) = rat_lam

    realbuf( 3) = rlam_mom
    realbuf( 4) = rlam_heat
    realbuf( 5) = rat_sea
    realbuf( 6) = rat_can
    realbuf( 7) = c_lnd
    realbuf( 8) = c_sea
    realbuf( 9) = c_soil
    realbuf(10) = e_surf
    realbuf(11) = pat_len
    realbuf(12) = z0m_dia
    realbuf(13) = tur_len
    realbuf(14) = a_heat
    realbuf(15) = a_mom
    realbuf(16) = d_heat
    realbuf(17) = d_mom
    realbuf(18) = c_diff
    realbuf(19) = a_hshr
    realbuf(20) = a_stab
    realbuf(21) = tkesmot
    realbuf(22) = wichfakt
    realbuf(23) = securi
    realbuf(24) = tkhmin
    realbuf(25) = tkmmin
    realbuf(26) = clc_diag
    realbuf(27) = q_crit
    realbuf(28) = qc0
    realbuf(29) = qi0
    realbuf(30) = gkdrag
    realbuf(31) = gkwake
    realbuf(32) = mu_rain
    realbuf(33) = cloud_num
    realbuf(34) = entr_sc
    realbuf(35) = thick_sc
    realbuf(36) = v0snow
    realbuf(37) = rain_n0_factor
  ENDIF

  CALL distribute_values (realbuf, 37, 0, imp_reals,    icomm_world, ierr)

  IF (my_world_id /= 0) THEN
    crsmin       = realbuf( 1)
    rat_lam      = realbuf( 2)

    rlam_mom     = realbuf( 3)
    rlam_heat    = realbuf( 4)
    rat_sea      = realbuf( 5)
    rat_can      = realbuf( 6)
    c_lnd        = realbuf( 7)
    c_sea        = realbuf( 8)
    c_soil       = realbuf( 9)
    e_surf       = realbuf(10)
    pat_len      = realbuf(11)
    z0m_dia      = realbuf(12)
    tur_len      = realbuf(13)
    a_heat       = realbuf(14)
    a_mom        = realbuf(15)
    d_heat       = realbuf(16)
    d_mom        = realbuf(17)
    c_diff       = realbuf(18)
    a_hshr       = realbuf(19)
    a_stab       = realbuf(20)
    tkesmot      = realbuf(21)
    wichfakt     = realbuf(22)
    securi       = realbuf(23)
    tkhmin       = realbuf(24)
    tkmmin       = realbuf(25)
    clc_diag     = realbuf(26)
    q_crit       = realbuf(27)
    qc0          = realbuf(28)
    qi0          = realbuf(29)
    gkdrag       = realbuf(30)
    gkwake       = realbuf(31)
    mu_rain      = realbuf(32)
    cloud_num    = realbuf(33)
    entr_sc      = realbuf(34)
    thick_sc     = realbuf(35)
    v0snow       = realbuf(36)
    rain_n0_factor=realbuf(37)
  ENDIF

ENDIF

!------------------------------------------------------------------------------
!- Section 6: Output of the namelist variables and their default values
!------------------------------------------------------------------------------

IF (my_world_id == 0) THEN

  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(A23)') '0     NAMELIST:  tuning'
  WRITE (nuspecif, '(A23)') '      -----------------'
  WRITE (nuspecif, '(A2)')  '  '
  WRITE (nuspecif, '(T7,A,T33,A,T51,A,T70,A)') 'Variable', 'Actual Value',   &
                                               'Default Value', 'Format'

  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                              'crsmin',crsmin,crsmin_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'rat_lam',rat_lam,rat_lam_d,' R '

  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'tkesmot',tkesmot,tkesmot_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'wichfakt',wichfakt,wichfakt_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'securi',securi,securi_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'tkhmin',tkhmin,tkhmin_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'tkmmin',tkmmin,tkmmin_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                        'rlam_mom',rlam_mom,rlam_mom_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                     'rlam_heat',rlam_heat,rlam_heat_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'rat_sea',rat_sea,rat_sea_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'rat_can',rat_can,rat_can_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'c_lnd',c_lnd,c_lnd_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'c_sea',c_sea,c_sea_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'c_soil',c_soil,c_soil_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'e_surf',e_surf,e_surf_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'pat_len',pat_len,pat_len_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'tur_len',tur_len,tur_len_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'z0m_dia',z0m_dia,z0m_dia_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'a_heat',a_heat,a_heat_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'a_mom',a_mom,a_mom_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'd_heat',d_heat,d_heat_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'd_mom',d_mom,d_mom_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'c_diff',c_diff,c_diff_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'a_hshr',a_hshr,a_hshr_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'a_stab',a_stab,a_stab_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                               'clc_diag',  clc_diag,  clc_diag_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'q_crit',q_crit,q_crit_d,' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'qc0',   qc0,    qc0_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                           'qi0',   qi0,    qi0_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'gkdrag', gkdrag, gkdrag_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                       'gkwake', gkwake, gkwake_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                    'mu_rain', mu_rain, mu_rain_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
               'rain_n0_factor', rain_n0_factor, rain_n0_factor_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,1PE12.2,T52,1PE12.4,T71,A3)')                  &
                                       'v0snow', v0snow, v0snow_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,1PE12.2,T52,1PE12.4,T71,A3)')                  &
                              'cloud_num', cloud_num, cloud_num_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                    'entr_sc', entr_sc, entr_sc_d,  ' R '
  WRITE (nuspecif, '(T8,A,T33,F12.4,T52,F12.4,T71,A3)')                      &
                                 'thick_sc', thick_sc, thick_sc_d,  ' R '
  WRITE (nuspecif, '(A2)')  '  '
ENDIF

!------------------------------------------------------------------------------
!- End of the Subroutine
!------------------------------------------------------------------------------

END SUBROUTINE input_tuning

!==============================================================================
!==============================================================================
!+ Subroutine for initialization of grid constants
!------------------------------------------------------------------------------

SUBROUTINE grid_constants

!------------------------------------------------------------------------------
!
! Description:
!   This routine initializes organizational variables needed for the 
!   special grid.
!
! Method:
!   Arithmetical statements
!
!------------------------------------------------------------------------------
!
!- End of header
!==============================================================================

! constants for the horizontal rotated grid and related variables
! ---------------------------------------------------------------

  eddlon    =   1.0_wp / (dlon * pi / 180.0_wp)
  eddlat    =   1.0_wp / (dlat * pi / 180.0_wp)
  edadlat   =   eddlat / r_earth
  dlonddlat =   dlon / dlat
  dlatddlon =   dlat / dlon

!- Further related variables
!------------------------------------------------------------------------------

  ! horizontal and vertical sizes of the fields and related variables
  ke1      = ke + 1
  kcm      = ke1        ! only one surface canopy layer so far
  ieje     = ie * je
  iejeke   = ieje * ke
  ieke     = ie * ke

  ! start- and end-indices for the computations in the horizontal layers
  istart   =  1 + nboundlines
  jstart   =  1 + nboundlines
  iend     = ie - nboundlines
  jend     = je - nboundlines

  istartu  =  1 + nboundlines
  jstartu  =  1 + nboundlines
  iendu    = ie - nboundlines
  IF ((my_cart_neigh(3) == -1) .AND. (lperi_x .EQV. .FALSE.)) THEN
    iendu = iendu - 1
  ENDIF
  jendu    = je - nboundlines

  istartv  =  1 + nboundlines
  jstartv  =  1 + nboundlines
  iendv    = ie - nboundlines
  jendv    = je - nboundlines
  IF ((my_cart_neigh(2) == -1) .AND. (lperi_y .EQV. .FALSE.)) THEN
    jendv = jendv - 1
  ENDIF
  IF ( l2dim ) THEN
    jendv  = jstartv
  ENDIF
  IF (my_cart_neigh(1) == -1 .OR. (lperi_x .AND. my_cart_pos(1) == 0) ) THEN
    istartpar = 1
  ELSE
    istartpar = 1 + nboundlines
  ENDIF

  IF (my_cart_neigh(4) == -1 .OR.(lperi_y .AND. my_cart_pos(2) == 0) ) THEN
    jstartpar = 1
  ELSE
    jstartpar = 1 + nboundlines
  ENDIF

  IF (my_cart_neigh(3) == -1 .OR. (lperi_x .AND. my_cart_pos(1) == nprocx-1) ) THEN
    iendpar   = ie
  ELSE
    iendpar   = ie - nboundlines
  ENDIF

  IF (my_cart_neigh(2) == -1 .OR. (lperi_y .AND. my_cart_pos(2) == nprocy-1) ) THEN
    jendpar   = je
  ELSE
    jendpar   = je - nboundlines
  ENDIF

END SUBROUTINE grid_constants

!==============================================================================
!==============================================================================
!+ Subroutine for initialization of the constant fields
!------------------------------------------------------------------------------

SUBROUTINE constant_fields

!------------------------------------------------------------------------------
!
! Description:
!   This routine initializes the constant fields that depend on the 
!   special grid
!
! Method:
!
!------------------------------------------------------------------------------

! Local variables:
REAL (KIND=wp)            ::  z2om, zlats, zlatsd, zlatd, zlons, zlonsd,     &
                              zifac, zjfac, zdtddtr, ztanfac,                &
                              zdrh, zdrv, zdru, zlatf,                       &
                              zq_rlwidth, zlbdz_thres, ztest

INTEGER (KIND=iintegers)  ::  i, j, k, i_td, j_td, j2dim, izerror,           &
                              i_mid, j_mid, i_hdm, j_hdm, hdm_lbcext,        &
                              i_west, i_east, j_south, j_north,              &
                              irel_west, irel_east, jrel_south, jrel_north,  &
                              istart_tot , iend_tot , jstart_tot , jend_tot, &
                              istartu_tot, iendu_tot, jstartu_tot, jendu_tot,&
                              istartv_tot, iendv_tot, jstartv_tot, jendv_tot

CHARACTER (LEN=80)        ::  yzerrmsg

!- End of header
!==============================================================================

  izerror  = 0
  yzerrmsg = '       '

! constant fields related to the grid (crlat, acrlat, rlat, rlon, fc, rmy)
! ---------------------------------------------------------------------

  z2om     = 4.0_wp * pi / day_len
  j_td = isubpos(my_cart_id,2) - nboundlines - 1
  DO j = 1 , je
    j_td = j_td + 1
    ! cos (lat) and 1 / cos (lat)
    zlats        = startlat_tot + (j_td-1) * dlat
    zlatsd       = zlats + 0.5_wp * dlat
    tgrlat (j,1) = TAN ( zlats  * degrad )
    tgrlat (j,2) = TAN ( zlatsd * degrad )
    crlat  (j,1) = COS ( zlats  * degrad )
    crlat  (j,2) = COS ( zlatsd * degrad )
    acrlat (j,1) = 1.0_wp / (r_earth * crlat(j,1))
    acrlat (j,2) = 1.0_wp / (r_earth * crlat(j,2))

    i_td = isubpos(my_cart_id,1) - nboundlines - 1
    DO i = 1 , ie
      i_td = i_td + 1
      ! geographical latitude and longitude
      zlons  = startlon_tot + (i_td-1) * dlon
      zlonsd = zlons + 0.5_wp * dlon

      IF (zlons  > 180.0_wp) THEN
        zlons  = zlons  - 360.0_wp
      ENDIF
      IF (zlonsd > 180.0_wp) THEN
        zlonsd = zlonsd - 360.0_wp
      ENDIF

      rlat(i,j) = phirot2phi ( zlats , zlons , pollat, pollon, polgam) * degrad
      rlon(i,j) = rlarot2rla ( zlats , zlons , pollat, pollon, polgam) * degrad

      ! Coriolis parameter fc
      zlatd     = phirot2phi ( zlatsd, zlonsd, pollat, pollon, polgam) * degrad
      fc  (i,j) = z2om * SIN (zlatd)

      ! Modification due to deep atmosphere, Ronny Petrik
      zlatf     = phirot2phi ( zlats,  zlons,  pollat, pollon, polgam) * degrad
      IF (lcori_deep) THEN
        fccos (i,j) = z2om * COS (zlatf)
      ENDIF

    ENDDO
  ENDDO

  ! the same for the fields rlon, rlat that are stored for the whole
  ! west-east total fields for the radiation
  IF ((nprocx > 1) .AND. (lreproduce)) THEN
    j_td = isubpos(my_cart_id,2) - nboundlines - 1
    DO j = 1 , je
      j_td = j_td + 1
      zlats        = startlat_tot + (j_td-1) * dlat
      DO i = 1 , ie_tot
        ! geographical latitude and longitude
        zlons  = startlon_tot + (i-1) * dlon
        IF (zlons  > 180.0_wp) THEN
          zlons  = zlons  - 360.0_wp
        ENDIF

        rlattot (i,j) = phirot2phi ( zlats , zlons , pollat, pollon, polgam) * degrad
        rlontot (i,j) = rlarot2rla ( zlats , zlons , pollat, pollon, polgam) * degrad
      ENDDO
    ENDDO
  ENDIF

  ! run without Coriolis-force
  IF (lcori .EQV. .FALSE.) THEN
    fc (:,:) = 0.0_wp
    ! No zero array needed, if running with deep atmosphere:
    ! terms won't be calculated
  ENDIF

  ! run without metric terms in an f-plane
  IF (lmetr .EQV. .FALSE.) THEN
    crlat (:,:) = 1.0_wp
    acrlat(:,:) = 1.0_wp / r_earth
    tgrlat(:,:) = 0.0_wp
    IF ( lcori .EQV. .TRUE. ) THEN ! Set fc to value for 45deg north
      fc (:,:) = z2om * SQRT(2.0_wp)/2.0_wp
    ENDIF

    ! Modification due to deep atmosphere, Ronny Petrik
    IF (lcori_deep) THEN 
      ! Set fccos to a value for 45deg north
      fccos (:,:) = z2om * SQRT(2.0_wp)/2.0_wp
    ENDIF

  ENDIF

  ! Davis-Parameter rmy for Arakawa-C-grid:
  ! --------------------------------------
  IF ( (lperi_x .AND. lperi_y) ) THEN
    ! periodic boundary conditions
    rmy (:,:,:) = 0.0_wp
    rmyq(:,:)   = 0.0_wp
  ELSE

    istart_tot   =  1     + nboundlines
    jstart_tot   =  1     + nboundlines
    iend_tot     = ie_tot - nboundlines
    jend_tot     = je_tot - nboundlines
 
    istartu_tot  =  1     + nboundlines
    jstartu_tot  =  1     + nboundlines
    ! iendu_tot is only needed below when NOT periodic in X-dir.,
    ! i.e., when my_cart_neigh(3) == -1, so we can just subtract -1
    ! safely without asking if (my_cart_neigh(3) == -1):
    iendu_tot    = ie_tot - nboundlines - 1
    jendu_tot    = je_tot - nboundlines
 
    istartv_tot  =  1     + nboundlines
    jstartv_tot  =  1     + nboundlines
    iendv_tot    = ie_tot - nboundlines
    ! jendv_tot is only needed below when NOT periodic in Y-dir.,
    ! i.e., when my_cart_neigh(2) == -1, so we can just subtract -1
    ! safely without asking if (my_cart_neigh(2) == -1):
    jendv_tot    = je_tot - nboundlines - 1

    ! factor for qr-, qs-, qg- relaxation layer
    zq_rlwidth = 0.2_wp * rlwidth

    !zifac   = dlon * 7000.0_wp / 0.0625_wp
    !zjfac   = dlat * 7000.0_wp / 0.0625_wp
    !MB: more clear is:
    zifac   = dlon * pi / 180.0_wp * r_earth
    zjfac   = dlat * pi / 180.0_wp * r_earth

    j_td = isubpos(my_cart_id,2) - nboundlines - 1

    DO j = 1 , je

      j_td = j_td + 1
      i_td = isubpos(my_cart_id,1) - nboundlines - 1

      DO i = 1 , ie

        i_td = i_td + 1

        ! rmy(:,:,1) is defined for the t, pp, qv, qc, qi - gridpoints
        ! rmyq(:,:)  is defined for the qr, qs, qg - gridpionts
        IF ( lperi_x ) THEN
          zdrh  =  MIN ( zjfac*(j_td - jstart_tot + 0.25_wp),   &
                         zjfac*(jend_tot - j_td   + 0.25_wp) )
        ELSE IF ( lperi_y ) THEN
          zdrh  =  MIN ( zifac*(i_td - istart_tot + 0.25_wp),   &
                         zifac*(iend_tot - i_td   + 0.25_wp) )
        ELSE
          zdrh  =  MIN ( zifac*(i_td - istart_tot + 0.25_wp),   &
                         zifac*(iend_tot - i_td   + 0.25_wp),   &
                         zjfac*(j_td - jstart_tot + 0.25_wp),   &
                         zjfac*(jend_tot - j_td   + 0.25_wp) )
        END IF

        rmy(i,j,1) = relax_fct( zdrh / rlwidth, crltau_inv )

        rmyq(i,j)  = relax_fct( zdrh / zq_rlwidth, crltau_inv )


        ! rmy(:,:,2) is defined for the u- gridpoints
        IF ( lperi_x ) THEN
          zdru  =  MIN ( zjfac*(j_td - jstartu_tot + 0.25_wp),   &
                         zjfac*(jendu_tot - j_td   + 0.25_wp) )
        ELSE IF ( lperi_y ) THEN
          zdru  =  MIN ( zifac*(i_td - istartu_tot + 0.75_wp),   &
                         zifac*(iendu_tot - i_td   + 0.75_wp) )
        ELSE
          zdru  =  MIN ( zifac*(i_td - istartu_tot + 0.75_wp),   &
                         zifac*(iendu_tot - i_td   + 0.75_wp),   &
                         zjfac*(j_td - jstartu_tot + 0.25_wp),   &
                         zjfac*(jendu_tot - j_td   + 0.25_wp) )
        END IF

        rmy(i,j,2) = relax_fct( zdru / rlwidth, crltau_inv )


        ! rmy(:,:,3) is defined for the v- gridpoints
        IF ( lperi_x ) THEN
          zdrv  =  MIN ( zjfac*(j_td - jstartv_tot + 0.75_wp),   &
                         zjfac*(jendv_tot - j_td   + 0.75_wp) )
        ELSE IF ( lperi_y ) THEN
          zdrv  =  MIN ( zifac*(i_td - istartv_tot + 0.25_wp),   &
                         zifac*(iendv_tot - i_td   + 0.25_wp) )
        ELSE
          zdrv  =  MIN ( zifac*(i_td - istartv_tot + 0.25_wp),   &
                         zifac*(iendv_tot - i_td   + 0.25_wp),   &
                         zjfac*(j_td - jstartv_tot + 0.75_wp),   &
                         zjfac*(jendv_tot - j_td   + 0.75_wp) )
        END IF

        rmy(i,j,3) = relax_fct( zdrv / rlwidth, crltau_inv )

      ENDDO

    ENDDO

    IF( l2dim ) THEN  ! Recalculate the Davis Parameter for 2-D Version

      IF ( .NOT.lperi_x ) THEN ! only for non-periodicity in x-direction

        j2dim = nboundlines + 1

        i_td = isubpos(my_cart_id,1) - nboundlines - 1
          
        DO i = 1 , ie
            
          i_td = i_td + 1
            
          zdrh  =  MIN ( i_td - istart_tot + 0.25_wp , iend_tot - i_td + 0.25_wp)
          zdrh  =  zifac * zdrh

          rmy(i,j2dim,1) = relax_fct( zdrh / rlwidth, crltau_inv )

          rmyq(i,j2dim)  = relax_fct( zdrh / zq_rlwidth, crltau_inv )

          zdru =  MIN ( i_td - istartu_tot + 0.75_wp , iendu_tot - i_td + 0.75_wp )
          zdru  =  zifac * zdru

          rmy(i,j2dim,2) = relax_fct( zdru / rlwidth, crltau_inv )


          rmy(i,:j2dim-1,1) = rmy(i,j2dim,1)
          rmy(i,j2dim+1:,1) = rmy(i,j2dim,1)
          rmyq(i,:j2dim-1)  = rmyq(i,j2dim)
          rmyq(i,j2dim+1:)  = rmyq(i,j2dim)
            
          rmy(i,:j2dim-1,2) = rmy(i,j2dim,2)
          rmy(i,j2dim+1:,2) = rmy(i,j2dim,2)

          rmy(i,:,3)        = rmy(i,j2dim,1)
          
        ENDDO

      ELSE
          
        ! 2D run and periodic in x-direction
        rmy(:,:,:) = 0.0_wp
        rmyq(:,:)  = 0.0_wp
          
      ENDIF

    ENDIF     ! end recalculation Davis Parameters for 2D version

  ENDIF

  ! set thresholds for start of the lateral boundary zone
  zlbdz_thres = 0.0_wp

  ! global indices of middle of the domain
  i_mid = ie_tot / 2 + 1
  j_mid = je_tot / 2 + 1

  ! set up mask for horizontal diffusion
  ! 1st step: HD at points in a frame according to the lateral relaxation zone
  ! (2nd step is done in init_relaxation for the upper levels)
  ! number of additional rows and columns where HD should be applied
  ! (extension of lateral boundary cond. zone)
  hdm_lbcext = 4

  ! initialize mask (was initialized to 1.0 in SR alloc_meteofields)
  hd_mask(:,:,:) = 0.0_wp

  WHERE( rmy(:,:,1) > zlbdz_thres )
    hd_mask(:,:,ke) = 1.0_wp
  END WHERE

  ! search global index in x-direction of the transition to
  ! the damping zone at western and eastern boundary
  i_west = ie_tot
  i_east = 1
  j_hdm = isubpos(my_cart_id,2) - nboundlines
  IF ( j_hdm + je-1 < j_mid ) THEN
    j_hdm = je
  ELSE IF ( j_hdm > j_mid ) THEN
    j_hdm = 1
  ELSE
    j_hdm = j_mid - j_hdm + 1
  END IF
  i_td = isubpos(my_cart_id,1) - nboundlines - 1
  DO i = 1, ie-1
    i_td = i_td + 1
    IF (       hd_mask(i  ,j_hdm,ke) == 1.0_wp                  &
         .AND. hd_mask(i+1,j_hdm,ke) == 0.0_wp ) i_west = i_td
    IF (       hd_mask(i+1,j_hdm,ke) == 1.0_wp                  &
         .AND. hd_mask(i  ,j_hdm,ke) == 0.0_wp ) i_east = i_td+1
  END DO

  ! search global index in y-direction of the transition to
  ! the damping zone at southern and northern boundary
  j_south = je_tot
  j_north = 1
  i_hdm = isubpos(my_cart_id,1) - nboundlines
  IF ( i_hdm + ie-1 < i_mid ) THEN
    i_hdm = ie
  ELSE IF ( i_hdm > i_mid ) THEN
    i_hdm = 1
  ELSE
    i_hdm = i_mid - i_hdm + 1
  END IF
  j_td = isubpos(my_cart_id,2) - nboundlines - 1
  DO j = 1, je-1
    j_td = j_td + 1
    IF (       hd_mask(i_hdm,j  ,ke) == 1.0_wp                  &
         .AND. hd_mask(i_hdm,j+1,ke) == 0.0_wp ) j_south = j_td
    IF (       hd_mask(i_hdm,j+1,ke) == 1.0_wp                  &
         .AND. hd_mask(i_hdm,j  ,ke) == 0.0_wp ) j_north = j_td+1
  END DO

  ! find global borders
  ! Extension from Oliver (MCH) for reproducible results
  IF (num_compute > 1) THEN
    CALL global_values (i_west,  1, 'MIN', imp_integers, icomm_cart, -1, &
                        yzerrmsg, izerror)
    CALL global_values (i_east,  1, 'MAX', imp_integers, icomm_cart, -1, &
                        yzerrmsg, izerror)
    CALL global_values (j_south, 1, 'MIN', imp_integers, icomm_cart, -1,&
                        yzerrmsg, izerror)
    CALL global_values (j_north, 1, 'MAX', imp_integers, icomm_cart, -1,&
                        yzerrmsg, izerror)
  ENDIF

  ! print borders
  IF ( my_world_id == 0 ) THEN
    IF ( i_west /= ie_tot )  PRINT *, "  hd_mask - SETUP: i_west  = ", i_west
    IF ( i_east /= 1 )       PRINT *, "  hd_mask - SETUP: i_east  = ", i_east
    IF ( j_south /= je_tot ) PRINT *, "  hd_mask - SETUP: j_south = ", j_south
    IF ( j_north /= 1 )      PRINT *, "  hd_mask - SETUP: j_north = ", j_north
  END IF

  ! extend mask for HD in x-direction
  IF (.NOT.lperi_x) THEN
    i_td = isubpos(my_cart_id,1) - nboundlines - 1
    DO i = 1, ie
      i_td = i_td + 1
      IF ( i_td > i_west .AND. i_td <= i_west+hdm_lbcext )    &
           hd_mask(i,:,ke) = 1.0_wp
      IF ( i_td < i_east .AND. i_td >= i_east-hdm_lbcext )    &
           hd_mask(i,:,ke) = 1.0_wp
    END DO
  END IF

  ! extend mask for HD in y-direction
  IF (.NOT.lperi_y) THEN
    j_td = isubpos(my_cart_id,2) - nboundlines - 1
    DO j = 1, je
      j_td = j_td + 1
      IF ( j_td > j_south .AND. j_td <= j_south+hdm_lbcext )  &
           hd_mask(:,j,ke) = 1.0_wp
      IF ( j_td < j_north .AND. j_td >= j_north-hdm_lbcext )  &
           hd_mask(:,j,ke) = 1.0_wp
    END DO
  END IF

  ! set remaining vertical levels of hd_mask equal to level ke
  ! (--> frame where HD should be applied)
  DO k = 1, ke-1
    hd_mask(:,:,k) = hd_mask(:,:,ke)
  END DO

  ! set up masks of lateral boundary zone for relaxation of moisture fields
  ! west - east direction

  ! Determine irel_west, irel_east, jrel_south, jrel_north for relaxation
  IF (.NOT.lperi_y) THEN

    jrel_north = jend_tot
    north: DO j = 1, je_tot
      ztest = (jend_tot - j + 0.25_wp) * zjfac
      IF (ztest < zq_rlwidth) THEN
        jrel_north = j
        EXIT north
      ENDIF
    ENDDO north
    
    jrel_south = 1
    south: DO j = 1, je_tot
      ztest = (j - jstart_tot + 0.25_wp) * zjfac
      IF (ztest >= zq_rlwidth) THEN
        jrel_south = j-1
        EXIT south
      ENDIF
    ENDDO south

    ! south - north direction
    j_td = isubpos(my_cart_id,2) - nboundlines - 1
    DO j = 1, je
      j_td = j_td + 1
      DO i = 1, ie
        IF (j_td < jrel_south .AND. rmyq(i,j) > zlbdz_thres) lsouth_lbdz(i,j) = .TRUE.
        IF (j_td > jrel_north .AND. rmyq(i,j) > zlbdz_thres) lnorth_lbdz(i,j) = .TRUE.
      END DO
    END DO

  END IF

  IF (.NOT.lperi_x) THEN

    irel_east = iend_tot
    east: DO i = 1, ie_tot
      ztest = (iend_tot - i + 0.25_wp) * zifac
      IF (ztest < zq_rlwidth) THEN
        irel_east  = i
        EXIT east
      ENDIF
    ENDDO east

    irel_west = 1
    west: DO i = 1, ie_tot
      ztest = (i - istart_tot + 0.25_wp) * zifac
      IF (ztest >= zq_rlwidth) THEN
        irel_west  = i-1
        EXIT west
      ENDIF
    ENDDO west
  
    ! west - east direction
    DO j = 1, je
      i_td = isubpos(my_cart_id,1) - nboundlines - 1
      DO i = 1, ie
        i_td = i_td + 1
        IF (i_td < irel_west .AND. rmyq(i,j) > zlbdz_thres) lwest_lbdz(i,j) = .TRUE.
        IF (i_td > irel_east .AND. rmyq(i,j) > zlbdz_thres) least_lbdz(i,j) = .TRUE.
      END DO
    END DO

  END IF


CONTAINS

  REAL (KIND=wp) FUNCTION  relax_fct( x, crltau_inv )

    ! Attenuation function for the Davis-relaxation at the lateral boundaries

    ! dimensionless distance from the lateral boundary:
    REAL (KIND=wp), INTENT(IN) :: x
    REAL (KIND=wp), INTENT(IN) :: crltau_inv

    if ( x <= 0.0_wp ) THEN
      relax_fct = 1.0_wp

    ELSE iF ( x >= 1.0_wp ) THEN
      relax_fct = 0.0_wp

    ELSE
      relax_fct = crltau_inv * EXP( - 6.0_wp * x )

      ! relax_fct = crltau_inv * ABS( 1.0_wp - x )**2
      ! relax_fct = crltau_inv * COS( 0.5_wp * pi * x )**2
      ! relax_fct = crltau_inv * ( 1.0_wp - tanh( 6.0_wp * x ) )

    END IF

  END FUNCTION relax_fct


END SUBROUTINE constant_fields

!==============================================================================
#ifndef SCLM
!==============================================================================
!+ Subroutine that decomposes the domain for distributed memory computers
!------------------------------------------------------------------------------

SUBROUTINE domain_decomposition

!------------------------------------------------------------------------------
!
! Description:
!   This subroutine computes the decomposition of the total LM domain. For 
!   dealing with the cartesian grid, it uses the following organizational
!   variables which are determined in init_procgrid.
!    - my_cart_id:       rank and id of this processor in the virtual topology
!    - my_cart_pos(2):   position in the cartesian processor grid in 
!                           x- and y-direction
!    - my_cart_neigh(4): neighbours of this processor in the order west, north,
!                        east, south
!    - icomm_cart:       MPI-communicator for the cartesian grid
!
!   With the above information, the decomposition of the total domain is 
!   computed. For every subdomain the indices of the lower left and the
!   upper right corner in the total domain are computed and stored in the
!   variable isubpos (num_compute,4) in the order (i_ll,j_ll,i_ur,j_ur).
!   Note that only the interior of the subdomains are considered and
!   boundary lines are neglected. That means
!
!         total domain                    subdomain
!
!      (i_ll,j_ll) corresponds to  (1+nboundlines , 1+nboundlines)
!      (i_ur,j_ur) corresponds to  (ie-nboundlines,je-nboundlines)
!
!   For the sequential program the variables are set accordingly.
!
! Method:
!
!------------------------------------------------------------------------------

! Local variables

  INTEGER (KIND=iintegers)   ::       &
    implcode, izerror, nzix2right, nzix2left, nzjy2lower, nzjy2upper, nz1d,  &
    ix, iy, nzsubi, nzsubj, nzcompi, nzcompj, nzix1, nzix2, nzjy1, nzjy2

  INTEGER (KIND=iintegers)   ::       &
    intvec(2)

  CHARACTER (LEN=75) yzerrmsg
  CHARACTER (LEN=25) yzroutine

!------------------------------------------------------------------------------
!- End of header -
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Begin SUBROUTINE domain_decomposition
!------------------------------------------------------------------------------

  implcode       = 0 
  yzroutine      = 'domain_decomposition'
 
!------------------------------------------------------------------------------
!- Section 1: Compute the domain decomposition
!------------------------------------------------------------------------------

  IF (num_compute > 1) THEN

  !----------------------------------------------------------------------------
  !- Section 1.1: Sizes and distribution of the subdomains
  !----------------------------------------------------------------------------

    ! Number of grid points that have to be distributed in each direction.
    ! The first nboundlines boundary lines of the total domain are not
    ! considered.
    nzcompi = ie_tot - 2*nboundlines
    nzcompj = je_tot - 2*nboundlines

    ! Number of grid points a subdomain gets at least: nzsubi, nzsubj
    nzsubi  = nzcompi / nprocx
    nzsubj  = nzcompj / nprocy

    ! Determine how many subdomains will get nzsubi (nzix1) and how many will
    ! get nzsubi+1 (nzix2) grid points: nzix1, nzix2
    nzix2   = nzcompi - nprocx * nzsubi
    nzix1   = nprocx - nzix2

    ! Determine how many subdomains will get nzsubj (nzjy1) and how many will
    ! get nzsubj+1 (nzjy2) grid points
    nzjy2   = nzcompj - nprocy * nzsubj
    nzjy1   = nprocy - nzjy2

    ! Determine the distribution of the subdomains with different sizes.
    ! The ones with more grid points are placed to the interior, the ones
    ! with less grid points to the boundary of the processor grid.
    nzix2left  = nzix1 / 2
    nzix2right = nzix1 - nzix2left
    nzjy2lower = nzjy1 / 2
    nzjy2upper = nzjy1 - nzjy2lower
   
  !----------------------------------------------------------------------------
  !- Section 1.2: Position of the subdomains in the total domain
  !----------------------------------------------------------------------------

    DO ix = 0,nprocx-1
      DO iy = 0,nprocy-1
        ! 1D numbering of the processors: rank
        nz1d = ix * nprocy + iy

        IF ( (0 <= iy) .AND. (iy <= nzjy2lower-1) ) THEN
          isubpos (nz1d,2) =  iy    *  nzsubj + nboundlines + 1
          isubpos (nz1d,4) = (iy+1) *  nzsubj + nboundlines
        ELSEIF ( (nzjy2lower <= iy) .AND. (iy <= nzjy2lower+nzjy2-1) ) THEN
          isubpos (nz1d,2) =  iy    * (nzsubj+1) - nzjy2lower + nboundlines + 1
          isubpos (nz1d,4) = (iy+1) * (nzsubj+1) - nzjy2lower + nboundlines
        ELSEIF ( (nzjy2lower+nzjy2 <= iy) .AND. (iy <= nprocy-1) ) THEN
          isubpos (nz1d,2) =  iy    *  nzsubj + nzjy2 + nboundlines + 1
          isubpos (nz1d,4) = (iy+1) *  nzsubj + nzjy2 + nboundlines
        ENDIF

        IF ( (0 <= ix) .AND. (ix <= nzix2left-1) ) THEN
          isubpos (nz1d,1) =  ix    *  nzsubi + nboundlines + 1
          isubpos (nz1d,3) = (ix+1) *  nzsubi + nboundlines
        ELSEIF ( (nzix2left <= ix) .AND. (ix <= nzix2left+nzix2-1) ) THEN
          isubpos (nz1d,1) =  ix    * (nzsubi+1) - nzix2left + nboundlines + 1
          isubpos (nz1d,3) = (ix+1) * (nzsubi+1) - nzix2left + nboundlines
        ELSEIF ( (nzix2left+nzix2 <= ix) .AND. (ix <= nprocx-1) ) THEN
          isubpos (nz1d,1) =  ix    *  nzsubi + nzix2 + nboundlines + 1
          isubpos (nz1d,3) = (ix+1) *  nzsubi + nzix2 + nboundlines
        ENDIF

      ENDDO
    ENDDO

  !----------------------------------------------------------------------------
  !- Section 1.3: Compute lmgrid variables for this subdomain
  !----------------------------------------------------------------------------

    ie = isubpos (my_cart_id,3) - isubpos (my_cart_id,1) + 1                 &
         + 2*nboundlines
    je = isubpos (my_cart_id,4) - isubpos (my_cart_id,2) + 1                 &
         + 2*nboundlines
    ke = ke_tot

    ! Calculate ie_max and je_max
    intvec(1) = ie
    intvec(2) = je
    CALL global_values (intvec, 2, 'MAX', imp_integers, icomm_cart, -1,      &
                        yzerrmsg, izerror)
    ie_max = intvec(1)
    je_max = intvec(2)

    startlon = startlon_tot + (isubpos(my_cart_id,1) - nboundlines - 1) * dlon
    startlat = startlat_tot + (isubpos(my_cart_id,2) - nboundlines - 1) * dlat 

    ! The longitude values have to be limited to the range (-180.0,+180.0)
    IF (startlon > 180.0_wp) THEN
      startlon = startlon - 360.0_wp
    ENDIF

  ELSE
    ! set the variables accordingly for the sequential program
    isubpos(0,1) = 1 + nboundlines
    isubpos(0,2) = 1 + nboundlines
    isubpos(0,3) = ie_tot - nboundlines
    isubpos(0,4) = je_tot - nboundlines
    ie           = ie_tot
    je           = je_tot
    ke           = ke_tot
    ie_max       = ie
    je_max       = je
    startlon     = startlon_tot
    startlat     = startlat_tot
  ENDIF

!------------------------------------------------------------------------------
!- End of the Subroutine
!------------------------------------------------------------------------------

END SUBROUTINE domain_decomposition
!==============================================================================
!+ Sends control information about the decomposition to the root
!------------------------------------------------------------------------------

SUBROUTINE check_decomposition (yerrmsg, ierror)

!------------------------------------------------------------------------------
!
! Description:
!   This subroutine puts the variables computed in domain_decomposition into
!   a buffer and sends it to the root-process where it is printed in a file
!   for debugging purposes.
!
! Method:
!
!------------------------------------------------------------------------------

! Subroutine arguments
  INTEGER (KIND=iintegers), INTENT(OUT) ::       &
    ierror                        ! error code

  CHARACTER (LEN=80)      , INTENT(OUT) ::       &
    yerrmsg                       ! error message

! Local variables

  INTEGER (KIND=iintegers), ALLOCATABLE  ::       &
    isendbuf(:),   & ! buffer for sending the variables
    irecvbuf(:,:)    ! buffer where the messages from all nodes are stored

  INTEGER (KIND=iintegers)   ::       &
    nzsendcount, nzrecvcount, nzroot, n, nzerr, niostat

  CHARACTER (LEN=25) yzroutine

!------------------------------------------------------------------------------
!- End of header -
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Begin SUBROUTINE check_decomposition
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
!- Section 1: Initializations
!------------------------------------------------------------------------------

  ! Initializations
  ierror      = 0
  yerrmsg     = '   '
  yzroutine   = 'check_decomposition'
  nzroot      = 0
  nzsendcount = 15
  nzrecvcount = nzsendcount

  ! Allocate the buffers
  ALLOCATE (isendbuf (nzsendcount), STAT=nzerr)
  IF (nzerr /= 0) THEN
    ierror  = 1011
    yerrmsg = 'allocation of space for buffers failed'
    RETURN
  ENDIF

  ! Would be necessary only in task 0, but some compilers complain, if it
  ! is not allocated.
  ALLOCATE (irecvbuf (nzrecvcount, 0:num_compute-1), STAT=nzerr)
  IF (nzerr /= 0) THEN
    ierror  = 1011
    yerrmsg = 'allocation of space for buffers failed'
    RETURN
  ENDIF

!------------------------------------------------------------------------------
!- Section 2:  Put own data into the sending buffer
!------------------------------------------------------------------------------

  ! Put data into isendbuf
  isendbuf ( 1) = my_cart_id
  isendbuf ( 2) = my_world_id
  isendbuf ( 3) = my_cart_pos(1)
  isendbuf ( 4) = my_cart_pos(2)
  isendbuf ( 5) = my_cart_neigh(1)
  isendbuf ( 6) = my_cart_neigh(2)
  isendbuf ( 7) = my_cart_neigh(3)
  isendbuf ( 8) = my_cart_neigh(4)
  isendbuf ( 9) = isubpos(my_cart_id,1)
  isendbuf (10) = isubpos(my_cart_id,2)
  isendbuf (11) = isubpos(my_cart_id,3)
  isendbuf (12) = isubpos(my_cart_id,4)
  isendbuf (13) = ie
  isendbuf (14) = je
  isendbuf (15) = ke

!------------------------------------------------------------------------------
!- Section 3: Gather the data from all nodes
!------------------------------------------------------------------------------

  CALL gather_values (isendbuf, irecvbuf, nzsendcount, num_compute,       &
                      imp_integers, nzroot, icomm_cart, yerrmsg, ierror)
  IF (ierror /= 0) THEN
    RETURN
  ENDIF

!------------------------------------------------------------------------------
!- Section 4: Print the data to the file YUDEBUG
!------------------------------------------------------------------------------

  IF (my_cart_id == 0) THEN

    OPEN(nudebug, FILE=yudebug  , FORM=  'FORMATTED', STATUS='UNKNOWN',  &
         IOSTAT=niostat)
    IF(niostat /= 0) THEN
      ierror  = 1012
      yerrmsg = ' ERROR    *** opening file YUDEBUG failed *** '
      RETURN
    ENDIF

    ! Print a headline in file YUDEBUG
    WRITE (nudebug, '(A2)')  '  '
    WRITE (nudebug, '(A50)')                                                 &
                  '0     The decomposition was calculated as follows:'
    WRITE (nudebug, '(A50)')                                                 &
                  '      ============================================'
    WRITE (nudebug, '(A2)')  '  '

    ! Print the information from all processes
    DO n = 0,num_compute-1
      WRITE (nudebug, '(A2)')  '  '
      WRITE (nudebug, '(A20,I10,A20,I10)')                                   &
      '       my_cart_id:  ',irecvbuf(1,n),'     my_world_id:  ',irecvbuf(2,n)
      WRITE (nudebug, '(A41,I2,A1,I2,A1)')                                   &
      '       Position in the cartesian grid:  (',                           &
                                          irecvbuf(3,n),',',irecvbuf(4,n),')'

      WRITE (nudebug, '(A41)') '       Neighbors in the cartesian grid:  '
      WRITE (nudebug, '(I50)')     irecvbuf(6,n)
      WRITE (nudebug, '(I40,I20)') irecvbuf(5,n), irecvbuf(7,n)
      WRITE (nudebug, '(I50)')     irecvbuf(8,n)

      WRITE (nudebug, '(A54)')                                               &
      '       Location of this subdomain in the total domain:'
      WRITE (nudebug, '(A13,I5,A5,I5,A13,I5,A5,I5)')                         &
      '         i = ',irecvbuf( 9,n),',...,',irecvbuf(11,n),                 &
      '         j = ',irecvbuf(10,n),',...,',irecvbuf(12,n)

      WRITE (nudebug, '(A36)') '       Dimensions of this subdomain:'
      WRITE (nudebug, '(A14,I4,A10,I4,A10,I4)')                              &
      '         ie = ',irecvbuf(13,n),'     je = ',irecvbuf(14,n),           &
      '     ke = ',irecvbuf(15,n)

      WRITE (nudebug, '(A2)')  '  '
    ENDDO

    ! Close file for debug output of the decomposition
    CLOSE (nudebug , STATUS='KEEP')

    ! Deallocate the buffers
    DEALLOCATE ( irecvbuf , STAT=nzerr)
  ENDIF

!------------------------------------------------------------------------------
!- End of the Subroutine
!------------------------------------------------------------------------------

  DEALLOCATE ( isendbuf , STAT=nzerr)

END SUBROUTINE check_decomposition
#endif

!==============================================================================

END MODULE src_setup
