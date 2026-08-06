# DY_fakePhoton_run3

Files for producing DY fake-photon NanoAOD sample for run3.

MC gen scripts are originally from Jaebak's repository: 
- https://github.com/jaebak/produceMC

Filter script from Xingchen's repository:
- https://github.com/xingchen-fan/DY_stat_boost





## Local test

Setup proxy:
```bash
voms-proxy-init --voms cms --out $(pwd)/voms_proxy.txt -valid 172:0
```



## CRAB job submission


If you want to submit CRAB job on your local server,
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
