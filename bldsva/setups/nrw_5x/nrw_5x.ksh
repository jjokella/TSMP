#! /bin/ksh

static_files=/p/scratch/cslts/shared_data/rcmod_TSMP-ref_SLTS/TestCases/nrw_5x
namelist_da=$rootdir/bldsva/setups/$refSetup/enkfpf.par
Npp=24

PFLProcX=1
PFLProcY=1
CLMProcX=4
CLMProcY=24
COSProcX=1
COSProcY=1

StartDate="2016-01-01 00"
InitDate="2016-01-02 00"

DumpCLM=1
DumpCOS=1
DumpPFL=1	

Runhours=24

gxCLM=300
gyCLM=300
dtCLM=1800
resCLM="0300x0300"

gxCOS=150
gyCOS=150
dtCOS=10
nboundlinesCOS=4

gxPFL=300
gyPFL=300
dtPFL=0.25
runnamePFL="rurlaf"
basePFL=0.0025


freq1OAS=900
freq2OAS=900

pdaf_screen_in=3
pdaf_filtertype_in=2
pdaf_subtype_in=1
pdaf_delt_obs_in=1
pdaf_rms_obs_in=0.02
pdaf_obs_filename_in="/p/scratch/cslts/shared_data/rcmod_TSMP-ref_SLTS/TestCases/nrw_5x/pdaf/obs/swc_obs"


finalizeSetupNRW5x(){
route "${cyellow}>> finalizeSetupNRW5x${cnormal}"

comment "copy PDAF files into rundir"
cp $rootdir/bldsva/setups/nrw_5x/create_ensemble_namelists.py $rundir
check
  
comment "create CLM5+PDAF run script"
check

cat << EOF >> $rundir/clm5pdaf_run.bsh
#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --time=02:00:00
#SBATCH --partition=batch
#SBATCH --job-name=C5P
#SBATCH --output=out-clm5pdaf.%j
#SBATCH --error=err-clm5pdaf.%j
#SBATCH --account=

nensemble=2

source $rundir/loadenvs
srun ./tsmp-pdaf -n_modeltasks \$nensemble -screen 3 -filtertype 2 -subtype 1 -delt_obs 1 -rms_obs 0.02 -obs_filename /p/scratch/cslts/shared_data/rcmod_TSMP-ref_SLTS/TestCases/nrw_5x/pdaf/obs/swc_obs

EOF
check

chmod +x $rundir/clm5pdaf_run.bsh >> $log_file 2>> $err_file
check

comment "Make necessary directories for CLM5 logs"
mkdir -p $rundir/timing/checkpoints
check
mkdir  $rundir/logs
check
route "${cyellow}<< finalizeSetupNRW5x${cnormal}"
}
