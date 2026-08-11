### Warning: This repo is not finished. I uploaded just to share the progress with Xingchen.

# DY_fakePhoton_run3

Files for producing DY fake jet photon NanoAOD sample for run3.

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
- Test with 100 events (~ 30 min.)





# CRAB submission

### Basic Setup
1. Log into LXPLUS

2. Go to your AFS home directory
  - For example, mine is
    ```bash
    /afs/cern.ch/user/j/junhyuk/
    ```

3. Clone this repository:
    ```bash
    git clone https://github.com/jhlee-003/DY_fakePhoton_run3.git
    ```

4. Check if you have your own directory in the `htozg-dy-privatemc` CERNBOX
   ```bash
   ls /eos/project/h/htozg-dy-privatemc
   ```
   - The script will automatically generate a new directory if you don't have it

### CRAB configuration file setup
First, you need to revise CRAB config file

```bash
# Go to config directory of specific a year
cd DY_fakePhoton_run3/2022/config

# Open Config file
vim *crabConfig.py
```
You're see `Edit below` at the bottom
- Press key `i` to start editing

Parameters to edit:
- `"stageout_dir=YOUR_DIR/2022"`: Replace `YOUR_DIR` with your directory name at `htozg-dy-privatemc` directory
  - If you don't have your directory, replace `YOUR_DIR` with your name (for example, `junhyuk`)
- `config.Data.totalUnits`: Number of jobs for the current task (default: 10,000 jobs)
  - Each job submits 10,000 events (10,000 jobs → 100,000,000 events)
- `config.Site.storageSite`: Storage site where you have write permission
- If you want to transfer outputs to your storage site, turn `transferOutputs` and `transferLogs` to `True`

When you're done, type `:wq!` to save and exit

### CRAB Submission

```bash
# Setup cmsenv:
cd /path/to/DY_fakePhoton_run3
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-el8
cmsrel CMSSW_14_0_21
cd CMSSW_14_0_21/src
cmsenv
cd -

# Go to a specific directory of a year
cd 2022

# Setup proxy (script requires proxy credential file / you can copy this file to other year's directory as long as it's valid)
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0

# Check if you have write permission (only if you want to transfer the output to storage site)
crab checkwrite --site=T2_KR_KISTI #Your storage site

# Submit crab task
crab submit -c config/*crabConfig.py
```


# Central MC dataset

I used following dataset for reference:

- 2022:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22NanoAODv12-130X_mcRun3_2022_realistic_v5-v5/NANOAODSIM

- 2022EE:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22EENanoAODv12-130X_mcRun3_2022_realistic_postEE_v6-v5/NANOAODSIM

- 2023:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23NanoAODv12-130X_mcRun3_2023_realistic_v14-v2/NANOAODSIM

- 2023BPix:
/DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23BPixNanoAODv12-130X_mcRun3_2023_realistic_postBPix_v2-v4/NANOAODSIM

- 2024:
