#!/bin/csh
# "Usage: ./assim.csh N c", N=0 or 1, c="clm", "cosmo", "parflow"
#
set MODEL_PATH="$ARCH/modelData/ideal_RTD_perfect/CLUMA2_1.2.0MCT_clm-cos-pfl_idealRTD_perfectModel"
set num_days = 13

# SELECT COMPONENT MODEL FOR ASSIMILATION
if ($2 == "cosmo") then
  set DART_DIR="$HOME/DART/lanai/models/terrsysmp/cosmo/work"
else if ($2 == "clm") then
  set DART_DIR="$HOME/DART/lanai/models/terrsysmp/clm/work"
else if ($2 == "parflow") then
  set DART_DIR="$HOME/DART/lanai/models/terrsysmp/parflow/work"
endif

# SELECT COMPILATION
if ($1 == 0) then
echo "-------------------------------------------------------------------------------"
echo "Update DART Source Code..."
echo "-------------------------------------------------------------------------------"
  ./git_to_dart_${2}.csh
endif

cd $DART_DIR 

if ($1 == 0) then
  echo "-------------------------------------------------------------------------------"
  echo "Compiling..."
  echo "-------------------------------------------------------------------------------"
  ./quickbuild.csh -mpi
  rm input.nml.*
  echo "-------------------------------------------------------------------------------"
  echo "Creating Perfect Obs..."
  echo "-------------------------------------------------------------------------------"
else if ($1 == 1) then
  echo "-------------------------------------------------------------------------------"
  echo "Creating Perfect Obs..."
  echo "-------------------------------------------------------------------------------"
else
  echo "-------------------------------------------------------------------------------"
  echo "Code not writtten for ..." $1
  echo "Usage: ./assim.csh N c", N=0 or 1, c="clm", "cosmo", "parflow"
  echo "-------------------------------------------------------------------------------"
  exit 1
endif
#
foreach irun (`seq 1 $num_days`)

if ($2 == "clm") then
set model_dir = `printf $MODEL_PATH%02d $irun`
set clmrst = `ls -1 $model_dir/clmoas.clm2.r* | tail -n -1`
set clmout = `ls -1 $model_dir/clmoas.clm2.h0* | tail -n -1`

set colum_exp = `printf column_export_out_%02d $irun`
echo "-------------------------------------------------------------------------------"
echo `pwd`
echo " "
echo "-------------------------------------------------------------------------------"
rm clm_restart.nc clm_history.nc 
rm True_State.nc perfect_restart
rm obs_seq.in dart_log.*
ln -sf $clmout clm_history.nc
ln -sf $clmrst clm_restart.nc 
#&model_nml has the above names for restart and netcdf file
endif  #$2 == "clm"

if ($2 == "cosmo") then
set model_dir = `printf $MODEL_PATH%02d $irun`
set clmrst = `ls -1 $model_dir/cosrst/lrff* | tail -n -1`
set clmout = `ls -1 $model_dir/cosout/lfff* | tail -n -1`
 
set colum_exp = `printf column_export_out_%02d $irun`
 
echo "-------------------------------------------------------------------------------"
echo `pwd`
echo " "
echo "-------------------------------------------------------------------------------"
rm cosmo.nc cosmo_prior
rm True_State.nc perfect_restart
rm obs_seq.in dart_log.*
ln -sf $cosout cosmo.nc
ln -sf $cosrst cosmo_prior
endif #$2 == "cosmo"

echo $DART_DIR
if ($irun == 1) then
#Generates output for create_obs_sequence, hardwired for Radiosonde Tempearture
echo "-------------------------------------------------------------------------------"
echo "Run column_rand ..."
echo "-------------------------------------------------------------------------------"
./column_rand
#Generate set_def.out
echo "-------------------------------------------------------------------------------"
echo "Run create_obs_sequence"
echo "-------------------------------------------------------------------------------"
./create_obs_sequence < column_rand.out
endif

#creates obs_seq.in, do it for one restart time 
set defaultInitDate  = `grep defaultInitDate $model_dir/cosmo_prior_time.txt`
echo $defaultInitDate[2]
sleep 3 
echo " "
echo "-------------------------------------------------------------------------------"
echo "Run create_fixed_network_seq..."
echo "-------------------------------------------------------------------------------"
./create_fixed_network_seq <$colum_exp
wait

echo "-------------------------------------------------------------------------------"
echo " Run ${2}"_to_dart"
echo "-------------------------------------------------------------------------------"
./${2}_to_dart

# creates 3 files including obs_seq.perfect 
echo "-------------------------------------------------------------------------------"
echo "Harvest model data: perfect_model_obs"
echo "-------------------------------------------------------------------------------"
./perfect_model_obs
mv obs_seq.perfect obs_seq.$defaultInitDate[2]

echo "-------------------------------------------------------------------------------"
echo "Exiting ..."
echo "-------------------------------------------------------------------------------"

end
exit 0
