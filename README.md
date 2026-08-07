# DY_fakePhoton_run3

Files for producing DY fake-photon NanoAOD sample for run3.

MC gen scripts are originally from Jaebak's repository: 
- https://github.com/jaebak/produceMC

Filter script from Xingchen's repository:
- https://github.com/xingchen-fan/DY_stat_boost



# Local test

```bash
# Go to a specific directory of the year that you want to test:
cd 2022

# Setup proxy:
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0

# Make a test directory & copy necessary files:
mkdir test
cd test
cp ../voms_proxy.txt .
cp ../config/*fragment.py .

# Test run:
bash ../ProduceDYfakePhoton*.sh 0 100 ../config/*.env 2>&1 | tee produce.log
```
- Test with 100 events (takes about 10-20 minutes depending on your server)





# CRAB task submission
First, you need to revise crab config file

```bash
# Go to config directory of specific a year
cd /path/to/DY_fakehPhoton_run3/2022/config

# Open Config file
vim *crabConfig.py
```
There are two parameters to edit 
- `config.Data.totalUnits`: Number of jobs for task
- `config.Site.storageSite`: The local server where you want to store the MC

Submission

```bash
# Setup cmsenv:
cd /path/to/DY_fakehPhoton_run3
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-el8
cmsrel CMSSW_14_0_21
cd CMSSW_14_0_21/src
cmsenv
cd -

# Go to a specific directory of a year
cd 2022

# Check if you have write permission
crab checkwrite --site=T2_KR_KISTI

# Submit crab task
crab submit -c config/*crabConfig.py
```


# Central MC dataset

I used following dataset for reference:

2022:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22NanoAODv12-130X_mcRun3_2022_realistic_v5-v5/NANOAODSIM

2022EE:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22EENanoAODv12-130X_mcRun3_2022_realistic_postEE_v6-v5/NANOAODSIM

2023:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23NanoAODv12-130X_mcRun3_2023_realistic_v14-v2/NANOAODSIM

2023BPix:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23BPixNanoAODv12-130X_mcRun3_2023_realistic_postBPix_v2-v4/NANOAODSIM

2024:
