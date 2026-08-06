# DY_fakePhoton_run3

Files for producing DY fake-photon NanoAOD sample for run3.

MC gen scripts are originally from Jaebak's repository: 
- https://github.com/jaebak/produceMC

Filter script from Xingchen's repository:
- https://github.com/xingchen-fan/DY_stat_boost


<br>

# Local test

```bash
# Setup proxy:
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0

# Go to a specific directory of the year that you want to test:
cd 2022

# Make a test directory & copy necessary files:
mkdir test
cd test
cp ../voms_proxy.txt .
cp ../config/*fragment.py .

# Test run:
../*.sh 0 100 ../config/*.env 2>&1 | tee produce.log
```
- Test with 100 events (takes about 10-20 minutes depending on your server)



<br>

# CRAB task submission

```bash
# Setup cmsenv:
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-el8
cmsrel CMSSW_14_0_21
cd CMSSW_14_0_21/src
cmsenv

# Check if you have write permission
crab checkwrite --site=T2_KR_KISTI
```
