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
  echo '    Fragment_filename="DYfakePhoton24_fragment.py"'
  echo '    AOD_NAME="DYto2L-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__RunIII2024Summer24DRPremix-140X_mcRun3_2024_realistic_v26-v1__privateProduction"'
  echo '    MINIAOD_NAME="DYto2L-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__RunIII2024Summer24MiniAODv6-150X_mcRun3_2024_realistic_v2-v1__privateProduction"'
  echo '    NANOAOD_NAME="DYto2L-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__RunIII2024Summer24NanoAODv15-150X_mcRun3_2024_realistic_v2-v1__privateProduction"'
  echo '    BASE_TAG="DYto2L-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer24"'
  exit
fi



source "$3"

required_vars=(Fragment_filename AOD_NAME MINIAOD_NAME NANOAOD_NAME BASE_TAG)
for name in "${required_vars[@]}"; do
  if [ -z "${!name:-}" ]; then
    echo "ERROR: $name is not set in $3"
    exit 2
  fi
done

echo "Set below variables with $3"
echo Fragment_filename \= $Fragment_filename
echo AOD_NAME \= $AOD_NAME
echo MINIAOD_NAME \= $MINIAOD_NAME
echo NANOAOD_NAME \= $NANOAOD_NAME
echo BASE_TAG \= $BASE_TAG

# Common software releases for the inclusive 2024 workflow.
readonly SCRAM_ARCH_VALUE="el8_amd64_gcc12"
readonly GENSIM_CMSSW="CMSSW_14_0_19"
readonly DIGIRECO_CMSSW="CMSSW_14_0_21"
readonly MININANO_CMSSW="CMSSW_15_0_4"


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
# Central flavor-specific references: wmLHEGS-00055, -00056, and -00057.
echo "Setting up CMSSW"
export SCRAM_ARCH=${SCRAM_ARCH_VALUE}
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r ${GENSIM_CMSSW}/src ] ; then
  echo release ${GENSIM_CMSSW} already exists
else
  scram p CMSSW ${GENSIM_CMSSW}
fi
cd ${GENSIM_CMSSW}/src
eval \`scram runtime -sh\`

# Setup custom fragment for CMSSW
mkdir -p Configuration/GenProduction/python
cp ../../config/${Fragment_filename} Configuration/GenProduction/python
scram b
cd ../..


echo "Make cmssw configuration file"
Output_filename=$AOD_NAME"__job-"${JOBNUM}"__SIM".root
cmsDriver.py Configuration/GenProduction/python/$Fragment_filename \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --beamspot DBrealistic \
  --step LHE,GEN,SIM \
  --geometry DB:Extended \
  --conditions 140X_mcRun3_2024_realistic_v26 \
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
# Central flavor-specific references: DRPremix-00071, -00072, and -00073.
echo "Setting up CMSSW"
export SCRAM_ARCH=${SCRAM_ARCH_VALUE}
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r ${DIGIRECO_CMSSW}/src ] ; then
  echo release ${DIGIRECO_CMSSW} already exists
else
  scram p CMSSW ${DIGIRECO_CMSSW}
fi
cd ${DIGIRECO_CMSSW}/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$AOD_NAME"__job-"${JOBNUM}"__SIM".root
Output_filename=$AOD_NAME"__job-"${JOBNUM}"__HLT".root
cmsDriver.py  \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --procModifiers premix_stage2 \
  --datamix PreMix \
  --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2024v14 \
  --geometry DB:Extended \
  --conditions 140X_mcRun3_2024_realistic_v26 \
  --datatier GEN-SIM-RAW \
  --eventcontent PREMIXRAW \
  --python_filename "$TAG"__DIGIPREMIX__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --pileup_input "dbs:/Neutrino_E-10_gun/RunIIISummer24PrePremix-Premixlib2024_140X_mcRun3_2024_realistic_v26-v1/PREMIX" \
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
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step RAW2DIGI,L1Reco,RECO,RECOSIM \
  --geometry DB:Extended \
  --conditions 140X_mcRun3_2024_realistic_v26 \
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

echo "----------------------------------MiniAODv6-------------------------------------"
# Based on the CMSSW_15_0_4 central setup used by MiniAODv6-00006.
echo "Setting up CMSSW"
export SCRAM_ARCH=${SCRAM_ARCH_VALUE}
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r ${MININANO_CMSSW}/src ] ; then
  echo release ${MININANO_CMSSW} already exists
else
  scram p CMSSW ${MININANO_CMSSW}
fi
cd ${MININANO_CMSSW}/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$AOD_NAME"__job-"${JOBNUM}.root
Output_filename=$MINIAOD_NAME"__job-"${JOBNUM}.root

# cmsDriver command
cmsDriver.py \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step PAT \
  --geometry DB:Extended \
  --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier MINIAODSIM \
  --eventcontent MINIAODSIM1 \
  --python_filename "$TAG"__MiniAODv6__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__MiniAODv6__cfg.py

echo "Clean up files"
rm -f \$Input_filename

echo "-----------------------------------NanoAODv15------------------------------------"
# Based on the CMSSW_15_0_4 central setup used by NanoAODv15-00006.
echo "Setting up CMSSW"
export SCRAM_ARCH=${SCRAM_ARCH_VALUE}
[[ $- == *u* ]] && U_WAS_ON=1 || U_WAS_ON=0; set +u; source /cvmfs/cms.cern.ch/cmsset_default.sh; ((U_WAS_ON)) && set -u
if [ -r ${MININANO_CMSSW}/src ] ; then
  echo release ${MININANO_CMSSW} already exists
else
  scram p CMSSW ${MININANO_CMSSW}
fi
cd ${MININANO_CMSSW}/src
eval \`scram runtime -sh\`
scram b
cd ../..

echo "Make cmssw configuration file"
Input_filename=$MINIAOD_NAME"__job-"${JOBNUM}.root
Output_filename=$NANOAOD_NAME"__job-"${JOBNUM}.root

# cmsDriver command
cmsDriver.py  \
  --scenario pp \
  --era Run3_2024 \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --step NANO \
  --conditions 150X_mcRun3_2024_realistic_v2 \
  --datatier NANOAODSIM \
  --eventcontent NANOAODSIM \
  --python_filename "$TAG"__NanoAODv15__cfg.py \
  --fileout file:\$Output_filename \
  --filein file:\$Input_filename \
  -n -1 \
  --no_exec \
  --mc

echo "Run cmssw with configuration file"
cmsRun "$TAG"__NanoAODv15__cfg.py


#-------CleanUp---------

echo "Clean up files"

rm -rf -- "${GENSIM_CMSSW}" "${DIGIRECO_CMSSW}" "${MININANO_CMSSW}"

rm -f ${TAG}__LHE__cfg.py
rm -f ${AOD_NAME}__job-${JOBNUM}__SIM_inLHE.root
rm -f "$TAG"__DIGIPREMIX__cfg.py
rm -f "$TAG"__AOD__cfg.py

rm -f ${TAG}__MiniAODv6__cfg.py
rm -f ${MINIAOD_NAME}__job-${JOBNUM}.root
rm -f ${TAG}__NanoAODv15__cfg.py

date

# End of "$TAG"_cmd.sh file
EndOfTestFile

echo "Made "$TAG"_cmd.sh"
chmod +x job_scripts/"$TAG"_cmd.sh

./job_scripts/${TAG}_cmd.sh
