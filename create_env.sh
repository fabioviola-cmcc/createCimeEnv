#!/bin/bash
#
# This script creates an environment made by: CESM, CIME, NEMO and WRF.
# It is almost fully automatic, but something requires a manual editing...
# At least for now!
#
# Input: an acronym to identify the new folder
#

########################################################
#
# Read input param
#
########################################################

if [[ -z $1 ]]; then
    echo "[createEnv] == Please, provide an acronym for this environment!"
    exit 1
fi

ACR=$1


########################################################
#
# Path config
#
########################################################

GLOB_CESMROOT=/work/opa/resm-dev/CESM
LOCAL_ROOT=${GLOB_CESMROOT}/$ACR/
LOCAL_CESMROOT=${LOCAL_ROOT}/cesm
LOCAL_CIMEROOT=${LOCAL_CESMROOT}/cime
LOCAL_CASEROOT=${LOCAL_CIMEROOT}/${ACR}_case
LOCAL_CASEOPROOT=${LOCAL_CIMEROOT}/${ACR}_case
LOCAL_WRFROOT=${LOCAL_CESMROOT}/components/wrf
LOCAL_NEMOROOT=${LOCAL_CESMROOT}/components/nemo
LOCAL_DLR=${LOCAL_CIMEROOT}/din_loc_root

if [[ -d $LOCAL_CESMROOT ]]; then
    echo "[createEnv] == Environment ${ACR} already exists!"
    exit 2
else
    echo "[createEnv] == Creating directory $LOCAL_CESMROOT"
    mkdir -p $LOCAL_ROOT
fi


########################################################
#
# Clone di CESM
#
########################################################

echo "[createEnv] == Downloading CESM in $LOCAL_CESMROOT"

cd $LOCAL_ROOT
git clone https://github.com/ihesp/cesm.git cesm


########################################################
#
# Edit Externals.cfg
#
########################################################

# create Externals.cfg
echo "[createEnv] == Creating file ${LOCAL_CESMROOT}/Externals.cfg"
echo "[cime]" > $LOCAL_CESMROOT/Externals.cfg
echo "branch = main" >> $LOCAL_CESMROOT/Externals.cfg
echo "protocol = git" >> $LOCAL_CESMROOT/Externals.cfg
echo "repo_url = git@github.com:fabioviola-cmcc/CIME_WrfNemoCoupling.git" >> $LOCAL_CESMROOT/Externals.cfg
echo "local_path = cime" >> $LOCAL_CESMROOT/Externals.cfg
echo -e "required = True\n" >> $LOCAL_CESMROOT/Externals.cfg
echo "[nemo]" >> $LOCAL_CESMROOT/Externals.cfg
echo "branch = main" >> $LOCAL_CESMROOT/Externals.cfg
echo "protocol = git" >> $LOCAL_CESMROOT/Externals.cfg
echo "repo_url = git@github.com:fabioviola-cmcc/NEMO_wrfcoupled.git" >> $LOCAL_CESMROOT/Externals.cfg
echo "local_path = components/nemo" >> $LOCAL_CESMROOT/Externals.cfg
echo -e "required = True\n" >> $LOCAL_CESMROOT/Externals.cfg
echo "[wrf]" >> $LOCAL_CESMROOT/Externals.cfg
echo "branch = main" >> $LOCAL_CESMROOT/Externals.cfg
echo "protocol = git" >> $LOCAL_CESMROOT/Externals.cfg
echo "repo_url = git@github.com:fabioviola-cmcc/WRF_nemocoupled.git" >> $LOCAL_CESMROOT/Externals.cfg
echo "local_path = components/wrf" >> $LOCAL_CESMROOT/Externals.cfg
echo -e "required = True\n" >> $LOCAL_CESMROOT/Externals.cfg
echo "[externals_description]" >> $LOCAL_CESMROOT/Externals.cfg
echo "schema_version = 1.0.0" >> $LOCAL_CESMROOT/Externals.cfg

# download the components
echo "[createEnv] == Downloading external components..."
cd $LOCAL_CESMROOT
./manage_externals/checkout_externals


########################################################
#
# Create case
#
########################################################

echo "[createEnv] == Creating case ${LOCAL_CASEROOT} ..."
cd $LOCAL_CIMEROOT
./scripts/create_newcase --compset 2000_WRF_SLND_SICE_NEMO_SROF_SGLC_SWAV --machine zeus --run-unsupported --res wrf6v1_nemo2v1 --case ${LOCAL_CASEROOT} --project 0419

echo "[createEnv] == Creating and setting DIN_LOC_ROOT to ${LOCAL_DLR} ..."
mkdir ${LOCAL_DLR}
cd $LOCAL_CASEROOT
./xmlchange DIN_LOC_ROOT=${LOCAL_DLR}
echo "[createEnv] == Do not forget to populate ${LOCAL_DLR} !!!"


########################################################
#
# Create bsub scripts
#
########################################################

echo "[createEnv] == Creating LSF scripts ..."

# create bsub_build
echo "#!/bin/bash" >> $LOCAL_CASEROOT/bsub_build.sh
echo "SCRIPT_EXE=${LOCAL_CASEROOT}/case.build" >> $LOCAL_CASEROOT/bsub_build.sh
echo "bsub -R \"span[ptile=1]\" -Is -q s_medium -P 0419 -J ${ACR}_build \"\$SCRIPT_EXE --verbose --skip-provenance-check\"" >> $LOCAL_CASEROOT/bsub_build.sh

# create bsub_run
echo "#!/bin/bash" >> $LOCAL_CASEROOT/bsub_run.sh
echo "SCRIPT_EXE=${LOCAL_CASEROOT}/case.submit" >> $LOCAL_CASEROOT/bsub_run.sh
echo "bsub -R \"span[ptile=1]\" -Is -q s_medium -P 0419 -J ${ACR}_run \"\$SCRIPT_EXE --verbose\"" >> $LOCAL_CASEROOT/bsub_run.sh


########################################################
#
# Create aliases
#
########################################################

echo "[createEnv] == Adding aliases to ~/.bash_profile ..."
echo -e "\n# ${ACR} CESM Environment" >> ~/.bash_profile
echo "${ACR}_CESMROOT=${LOCAL_CESMROOT}" >> ~/.bash_profile
echo "${ACR}_CIMEROOT=${LOCAL_CIMEROOT}" >> ~/.bash_profile
echo "${ACR}_CASEROOT=${LOCAL_CASEROOT}" >> ~/.bash_profile
echo "${ACR}_CASEOPROOT=${LOCAL_CASEOPROOT}" >> ~/.bash_profile
echo "${ACR}_WRF=${LOCAL_WRFROOT}" >> ~/.bash_profile
echo "${ACR}_NEMO=${LOCAL_NEMOROOT}" >> ~/.bash_profile
echo "${ACR}_DIN_LOC_ROOT=${LOCAL_DLR}" >> ~/.bash_profile
