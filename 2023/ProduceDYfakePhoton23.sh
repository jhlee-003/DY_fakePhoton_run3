#!/bin/bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "[Usage] $0 JOB_NUMBER NUMBER_OF_EVENTS ENV_FILE"
  echo "  JOB_NUMBER is used for file names and run number to randomize between jobs"
  echo "  ENV_FILE is used to set names"
  exit
fi


if [ ! -f "$3" ]; then
  echo "ENV_FILE does not exist"
  echo "  ENV_FILE : Sets names for Fragment_filename, AOD_NAME, MINIAOD_NAME, NANOAOD_NAME, BASE_TAG"
  echo '  Example'
  echo '    Fragment_filename="DYfakePhoton23_fragment.py"'
  echo '    AOD_NAME="DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer23DRPremix-130X_mcRun3_2023_realistic_v14__privateProduction"'
  echo '    MINIAOD_NAME="DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer23MiniAODv4-130X_mcRun3_2023_realistic_v14__privateProduction"'
  echo '    NANOAOD_NAME="DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer23NanoAODv12-130X_mcRun3_2023_realistic_v14__privateProduction"'
  echo '    BASE_TAG="DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer23"'
  exit
fi



source "$3"
echo "Set below variables with $3"
echo Fragment_filename \= $Fragment_filename
echo AOD_NAME \= $AOD_NAME
echo MINIAOD_NAME \= $MINIAOD_NAME
echo NANOAOD_NAME \= $NANOAOD_NAME
echo BASE_TAG \= $BASE_TAG


# Set variables
JOBNUM=$(($1+1)) #$1 will start from 0. Need to add at least 1.
NEVENTS=$2
TAG="$BASE_TAG""__job-"${JOBNUM}

mkdir -p config
[[ -e "$Fragment_filename" ]] && mv "$Fragment_filename" config

if [ ! -f "config/${Fragment_filename}" ]; then
  echo "config/${Fragment_filename} does not exist"
  exit
fi

if [ ! -f "voms_proxy.txt" ]; then
  echo "voms_proxy.txt does not exist"
  echo "use the following command: "
  echo "voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0"
  exit
fi

export X509_USER_PROXY=$(pwd)/voms_proxy.txt

mkdir -p job_scripts

cat <<EndOfTestFile > job_scripts/"$TAG"_cmd.sh
#!/bin/bash
set -euo pipefail
date


echo "--------------------------------LHE,GEN,SIM-------------------------------------"
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/GEN-Run3Summer23wmLHEGS-00330
echo "Setting up CMSSW"
export SCRAM_ARCH=el8_amd64_gcc11
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r CMSSW_13_0_14/src ] ; then
  echo release CMSSW_13_0_14 already exists
else
  scram p CMSSW CMSSW_13_0_14
fi
cd CMSSW_13_0_14/src
eval \`scram runtime -sh\`

# Setup custom fragment for CMSSW
mkdir -p Configuration/GenProduction/python
cp ../../config/${Fragment_filename} Configuration/GenProduction/python
scram b
cd ../..


echo "Make cmssw configuration file"
Output_filename=$AOD_NAME"__job-"${JOBNUM}"__SIM".root
cmsDriver.py Configuration/GenProduction/python/$Fragment_filename \
  --era Run3_2023 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --beamspot Realistic25ns13p6TeVEarly2023Collision \
  --step LHE,GEN,SIM \
  --geometry DB:Extended \
  --conditions 130X_mcRun3_2023_realistic_v14 \
  --customise_commands \
    "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(200); from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()" \
  --datatier GEN-SIM,LHE \
  --eventcontent RAWSIM,LHE \
  --python_filename "$TAG"__LHE__cfg.py \
  --fileout file:\$Output_filename \
  -n $NEVENTS \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__LHE__cfg.py

echo "---------------------------------DIGIPREMIX------------------------------------"
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/GEN-Run3Summer23DRPremix-00246
echo "Setting up CMSSW"
export SCRAM_ARCH=el8_amd64_gcc11
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r CMSSW_13_0_14/src ] ; then
  echo release CMSSW_13_0_14 already exists
else
  scram p CMSSW CMSSW_13_0_14
fi
cd CMSSW_13_0_14/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$AOD_NAME"__job-"${JOBNUM}"__SIM".root
Output_filename=$AOD_NAME"__job-"${JOBNUM}"__HLT".root
cmsDriver.py  \
  --era Run3_2023 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --procModifiers premix_stage2 \
  --datamix PreMix \
  --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2023v12 \
  --geometry DB:Extended \
  --conditions 130X_mcRun3_2023_realistic_v14 \
  --datatier GEN-SIM-RAW \
  --eventcontent PREMIXRAW \
  --python_filename "$TAG"__DIGIPREMIX__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --pileup_input "dbs:/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23_130X_mcRun3_2023_realistic_v13-v1/PREMIX" \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__DIGIPREMIX__cfg.py

echo "Clean up files"
rm -f \$Input_filename

echo "------------------------------------RECO----------------------------------------"
echo "Make cmssw configuration file"
Input_filename=$AOD_NAME"__job-"${JOBNUM}"__HLT".root
Output_filename=$AOD_NAME"__job-"${JOBNUM}.root

cmsDriver.py  \
  --era Run3_2023 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step RAW2DIGI,L1Reco,RECO,RECOSIM \
  --geometry DB:Extended \
  --conditions 130X_mcRun3_2023_realistic_v14 \
  --datatier AODSIM \
  --eventcontent AODSIM \
  --python_filename "$TAG"__AOD__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__AOD__cfg.py

echo "Clean up files"
rm -f \$Input_filename

echo "----------------------------------MiniAODv4-------------------------------------"
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/GEN-Run3Summer23MiniAODv4-00246
echo "Setting up CMSSW"
export SCRAM_ARCH=el8_amd64_gcc11
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r CMSSW_13_0_14/src ] ; then
  echo release CMSSW_13_0_14 already exists
else
  scram p CMSSW CMSSW_13_0_14 
fi
cd CMSSW_13_0_14/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$AOD_NAME"__job-"${JOBNUM}.root
Output_filename=$MINIAOD_NAME"__job-"${JOBNUM}.root

# cmsDriver command
cmsDriver.py \
  --era Run3_2023 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step PAT \
  --geometry DB:Extended \
  --conditions 130X_mcRun3_2023_realistic_v14 \
  --datatier MINIAODSIM \
  --eventcontent MINIAODSIM \
  --python_filename "$TAG"__MiniAODv4__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__MiniAODv4__cfg.py

echo "Clean up files"
rm -f \$Input_filename

echo "-----------------------------------NanoAODv12------------------------------------"
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_setup/GEN-Run3Summer23NanoAODv12-00246
echo "Setting up CMSSW"
export SCRAM_ARCH=el8_amd64_gcc11
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r CMSSW_13_0_14/src ] ; then
  echo release CMSSW_13_0_14 already exists
else
  scram p CMSSW CMSSW_13_0_14
fi
cd CMSSW_13_0_14/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$MINIAOD_NAME"__job-"${JOBNUM}.root
Output_filename=$NANOAOD_NAME"__job-"${JOBNUM}.root

# cmsDriver command
cmsDriver.py  \
  --scenario pp \
  --era Run3_2023 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step NANO \
  --conditions 130X_mcRun3_2023_realistic_v14 \
  --datatier NANOAODSIM \
  --eventcontent NANOAODSIM \
  --python_filename "$TAG"__NanoAODv12__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__NanoAODv12__cfg.py


#-------CleanUp---------

echo "Clean up files"

rm -rf CMSSW_13_0_14

rm -f ${TAG}__LHE__cfg.py
rm -f ${AOD_NAME}__job-${JOBNUM}__SIM_inLHE.root
rm -f "$TAG"__DIGIPREMIX__cfg.py
rm -f "$TAG"__AOD__cfg.py

rm -f ${TAG}__MiniAODv4__cfg.py
rm -f ${MINIAOD_NAME}__job-${JOBNUM}.root
rm -f ${TAG}__NanoAODv12__cfg.py

date

# End of "$TAG"_cmd.sh file
EndOfTestFile

echo "Made "$TAG"_cmd.sh"
chmod +x job_scripts/"$TAG"_cmd.sh

./job_scripts/${TAG}_cmd.sh
