#!/bin/csh -f

cat << EndOfText >! exclude-list.txt
*.swp
*.mod
dart_log.*
Makefile
input*default
advance_time
parflow_to_dart
create_obs_sequence
dart_to_parflow
fill_inflation_restart
filter
model_mod_check
obs_sequence_tool
perfect_model_obs
preprocess
EndOfText

set DEST = $HOME/DART/lanai/models/terrsysmp/parflow/
set SOURCE = $HOME/terrsysmp/bldsva/intf_DA/dart/parflow/

rsync -Cavzr --exclude-from=exclude-list.txt ${SOURCE} ${DEST}

echo "to finish up ... "
echo "cd ${DEST}"
