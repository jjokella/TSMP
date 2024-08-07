#! /bin/ksh

initSetup(){
  defaultFDCLM="/homea/hbn33/hbn331/database/seabreeze/clm"
  defaultFDCOS="/homea/hbn33/hbn331/database/seabreeze/cosmo"
  defaultFDOAS="/homea/hbn33/hbn331/database/seabreeze/oasis3"
  defaultFDPFL="/homea/hbn33/hbn331/database/seabreeze/parflow"

  defaultNLCLM=$rootdir/bldsva/setups/seabreeze/lnd.stdin 
  defaultNLCOS=$rootdir/bldsva/setups/seabreeze/lmrun_uc 
  defaultNLPFL=$rootdir/bldsva/setups/seabreeze/coup_oas.tcl


  defaultNppn=48
  defaultCLMProcX=4
  defaultCLMProcY=10
  defaultCOSProcX=10
  defaultCOSProcY=10
  defaultPFLProcX=10
  defaultPFLProcY=2

  defaultStartDate="2017-03-27 00"
  defaultInitDate="2017-03-27 00"
  defaultRunhours=24

  defaultDumpCLM=1
  defaultDumpCOS=1
  defaultDumpPFL=1


  gx_clm=294
  gy_clm=94
  dt_clm=18
  res="0094x0294"

  gx_cos=300
  gy_cos=100
  dt_cos=18
  nbndlines=3

  gx_pfl=24
  gy_pfl=14
  dt_pfl=0.005
  pflrunname="rurlaf"
  base_pfl=0.0025

  cplfreq1=18
  cplfreq2=18


  if [[ $withPFL == "false" && $withCOS == "true" ]]; then
    if [[ $cplscheme == "false" ]]; then
      defaultNLOAS=$rootdir/bldsva/data_oas3/namcouple_cos_clm_a1
    else	
      defaultNLOAS=$rootdir/bldsva/data_oas3/namcouple_cos_clm
    fi	
  fi	
  if [[ $withPFL == "true" && $withCOS == "false" ]]; then
    defaultNLOAS=$rootdir/bldsva/data_oas3/namcouple_pfl_clm
  fi
  if [[ $withPFL == "true" && $withCOS == "true" ]]; then
    if [[ $cplscheme == "false" ]]; then
      defaultNLOAS=$rootdir/bldsva/data_oas3/namcouple_cos_clm_pfl_a1
    else
      defaultNLOAS=$rootdir/bldsva/data_oas3/namcouple_cos_clm_pfl
    fi
  fi

}

finalizeSetup(){
route "${cyellow}>> finalizeSetup${cnormal}"
  if [[ $withOAS == "true" ]] then
    comment "   copy clmgrid into rundir"
      cp $forcingdir_clm/grid* $rundir/clmgrid.nc >> $log_file 2>> $err_file
    check

    comment "   copy oasis remappingfiles into rundir"
      cp $forcingdir_oas/* $rundir >> $log_file 2>> $err_file
    check
    if [[ $withOASMCT == "true" ]] then
      for x in $rundir/*BILINEA* ;do 
        comment "   rename oasis3 remapping files" 
          mv $x $(echo $x | sed "s/BILINEA/BILINEAR/") >> $log_file 2>> $err_file
        check 
      done
    fi  
  fi  

  if [[ $withPFL == "true" ]] then


        comment "   cd to rundir"
          cd $rundir >> $log_file 2>> $err_file
        check
        comment "   copy initial pressure and script into rundir"
        cp $forcingdir_pfl/pfb*.nc $rundir/ >> $log_file 2>> $err_file
        check
        comment "   copy initial pressure and script into rundir"
          cp $forcingdir_pfl/ascii2pfb.tcl $rundir/ascii2pfb.tcl >> $log_file 2>> $err_file
        check
          cp $forcingdir_pfl/rur_ic_press.pfb $rundir >> $log_file 2>> $err_file
        check
          chmod u+w $rundir/rur_ic_press.pfb  $rundir/ascii2pfb.tcl >> $log_file 2>> $err_file
        check
        comment "   sed procs into pfbscript"
          sed "s,lappend auto_path.*,lappend auto_path $bindir/bin," -i $rundir/ascii2pfb.tcl >> $log_file 2>> $err_file
        check
          sed "s,pfset Process\.Topology\.P.*,pfset Process\.Topology\.P $px_pfl," -i $rundir/ascii2pfb.tcl >> $log_file 2>> $err_file
        check
          sed "s,pfset Process\.Topology\.Q.*,pfset Process\.Topology\.Q $py_pfl," -i $rundir/ascii2pfb.tcl >> $log_file 2>> $err_file
        check
        comment "   create sloap pfb with tclsh"
          tclsh ./ascii2pfb.tcl >> $log_file 2>> $err_file
        check
              

  fi 
route "${cyellow}<< finalizeSetup${cnormal}"
}
