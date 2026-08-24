# DY_fakePhoton_run3

Files for producing DY fake jet photon NanoAOD sample for run3.

MC gen scripts are originally from Jaebak's repository: 
- https://github.com/jaebak/produceMC

Filter script from Xingchen's repository:
- https://github.com/xingchen-fan/DY_stat_boost

About 2024 script:
- There are 2024 central mc sample for each hard scattering lepton flavor.
- 2024FlavorSplit directory is for producing separate mc sample for each lepton flavor.
  - Different gridpacks used for e/mu vs. tau
  - Different CMSSW version for production of Mini/NanoAOD files
- 2024 directory is for producing inclusive mc sample like the previous years.
  - Used e/mu gridpack + most recent CMSSW version for inclusive 2024 DY production script.
- Recommend using 2024 directory.

<br>




# Local test (not mandatory)

Note: not recommended on LXPLUS

Go to a specific directory of the year that you want to test:

```bash
cd DY_fakePhoton_run3/2022
```

Setup proxy & valid cmssw:

```bash
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-el8
```

Make a test directory & copy necessary files & Test run:

```bash
mkdir test
cd test
cp ../voms_proxy.txt .
cp ../config/*fragment.py .
bash ../ProduceDYfakePhoton*.sh 0 100 ../config/*.env 2>&1 | tee produce.log
```
- Test with 100 events (~ 30 min.)



<br>

# CRAB submission (LXPLUS)

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

<br>

### CMSSW environment setup

Go to repo directory if you're not:
```bash
cd /path/to/DY_fakePhoton_run3
```

Setup CMSSW environment:
```bash
cmssw-el8
cmsrel CMSSW_14_0_21
cd CMSSW_14_0_21/src
cmsenv
cd -
```

<br>

### CRAB configuration file setup
Go to specific a year (2022 for example) & open CRAB config file:

```bash
cd 2022
vim config/*crabConfig.py
```

You're see `Edit below` at the bottom.
```bash
#--------------------------Edit Below--------------------------
    "stageout_dir=YOUR_DIR/2022"         # Your directory name inside htozg-dy-privatemc directory
]
config.Data.totalUnits  = 10000          # Number of CRAB jobs
config.Site.storageSite = "T3_KR_KNU"    # Storage site where you have write permission (Required syntactically by CRAB)
config.General.transferOutputs = False   # Change to `True` if you want to transfer your output to your storage site
config.General.transferLogs = False      # Change to `True` if you want to transfer the log to your storage site
```
- Press key `i` to start editing

Parameters to edit:
- `"stageout_dir=YOUR_DIR/2022"`: Replace `YOUR_DIR` with your directory name at `htozg-dy-privatemc` directory.
  - If you don't have your directory, replace `YOUR_DIR` with your preferred name that doesn't overlap with others (for example, `junhyuk`).
  - This will automatically generate a new directory under `/eos/project/h/htozg-dy-privatemc`.
  - Use that directory for the future MC production.
- `config.Data.totalUnits`: Number of jobs for the current task (default: 10,000 jobs is also max. jobs per each task)
  - Each job submits 10,000 events (10,000 jobs → 100,000,000 events)
  - Recommend submitting 10,000 jobs per task unless needed otherwise
- `config.Site.storageSite`: Storage site where you have write permission
- If you want to transfer outputs to your storage site, turn `transferOutputs` and `transferLogs` to `True`

When you're done, type `:wq!` to save and exit

<br>

### CRAB Submission

You should be inside specific year's directory.

Setup proxy (script requires proxy credential file / you can copy this file to other year's directory as long as it's valid):
```bash
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0
```
- You can skip this if you already have valid proxy file in the current directory

Check if you have write permission (only if you want to transfer the output to storage site):
```
crab checkwrite --site=T3_KR_KISTI
```

Check if you have all the necessary files before submission
```bash
ls
ls config
```
- You should see
  ```bash
  Singularity> ls
  PSet.py  ProduceDYfakePhoton22.sh  config  crab_convert_wrapper.sh voms_proxy.txt
  Singularity> ls config
  DYfakePhoton22_FullSim.env  DYfakePhoton22_crabConfig.py  DYfakePhoton22_fragment.py
  ```

Submit crab task:
```
crab submit -c config/*crabConfig.py
```

<br>

### Whitelist (optional)
10-20% failure rate is expected per each task without whitelist
- Setting whitelist could reduce the failure rate

Revise crab config file:
```bash
vim config/*crabConfig.py
```

Add this block below `config.section_("Site")`
```
config.Site.whitelist = [
    "T2_CH_CERN",
    "T2_IT_Bari",
    "T2_DE_DESY",
    "T2_IT_Rome",
    "T2_TR_METU",
    "T2_CN_Beijing",
    "T2_ES_CIEMAT",
    "T2_FR_IPHC",
    "T2_IT_Legnaro",
]
```
- This list is made purely based on my personal experience
- You can add/remove sites based on your use case
- I recommend always keeping `T2_CH_CERN` in the list

<br>



# Central MC dataset

I used following dataset for reference:

- 2022:
  - /DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22NanoAODv12-130X_mcRun3_2022_realistic_v5-v5/NANOAODSIM

- 2022EE:
  - /DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer22EENanoAODv12-130X_mcRun3_2022_realistic_postEE_v6-v5/NANOAODSIM

- 2023:
  - /DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23NanoAODv12-130X_mcRun3_2023_realistic_v14-v2/NANOAODSIM

- 2023BPix:
  - /DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/Run3Summer23BPixNanoAODv12-130X_mcRun3_2023_realistic_postBPix_v2-v4/NANOAODSIM

- 2024:
  - /DYto2E-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/RunIII2024Summer24NanoAODv15-150X_mcRun3_2024_realistic_v2-v4/NANOAODSIM
  - /DYto2Mu-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/RunIII2024Summer24NanoAODv15-150X_mcRun3_2024_realistic_v2-v6/NANOAODSIM
  - /DYto2Tau-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8/RunIII2024Summer24NanoAODv15-150X_mcRun3_2024_realistic_v2-v7/NANOAODSIM
