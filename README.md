# DY_fakePhoton_run3

Files for producing DY fake-photon NanoAOD sample for run3.

MC gen scripts are originally from Jaebak's repository: 
- https://github.com/jaebak/produceMC

Filter script from Xingchen's repository:
- https://github.com/xingchen-fan/DY_stat_boost


<br>

# Local test

Setup proxy:
```bash
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0
```
Go to a specific directory of the year that you want to test:
```
cd 2022
```
Make a test directory & copy necessary files:
```bash
mkdir test
cd test
cp ../voms_proxy.txt .
cp ../config/*fragment.py .
```
Test run:
```bash
../*.sh 0 100 ../config/*.env 2>&1 | tee produce.log
```
- Test with 100 events (takes about 10-20 minutes depending on your server)



<br>

# CRAB task submission

If you want to submit CRAB task on your local server,
```bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-el8
export SCRAM_ARCH=el8_amd64_gcc10
```
and run
```bash
./initSetup.sh
```
It may take few minutes depending on your connection.
