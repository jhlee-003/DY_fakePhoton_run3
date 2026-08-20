from WMCore.Configuration import Configuration
config = Configuration()

import os
from datetime import datetime, timezone

submission_tag = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%SUTC")

work_area = "crab_projects"
base = "DY_FakePhoton_Run3_24_Tau_FullSim"

# Set task number
n = 1
while True:
    req = "{}{}".format(base, n)
    path1 = os.path.join(work_area, "crab_{}".format(req))
    if not os.path.exists(path1):
        break
    n += 1

config.section_("General")
config.General.requestName = req
config.General.workArea = work_area

config.section_("Debug")
config.section_("JobType")
config.JobType.pluginName  = "PrivateMC"
config.JobType.psetName    = "PSet.py"
config.JobType.scriptExe   = "crab_convert_wrapper.sh"
config.JobType.numCores = 2
config.JobType.maxMemoryMB = 5000
config.JobType.maxJobRuntimeMin = 900
config.Debug.extraJDL = ["request_disk = 8000000"]
config.JobType.inputFiles  = [
    "voms_proxy.txt",
    "config/DYfakePhoton24Tau_FullSim.env",
    "config/DYfakePhoton24Tau_fragment.py",
    "ProduceDYfakePhoton24Tau.sh"
]
config.JobType.outputFiles = [
    "DYto2Tau-2Jets_Bin-MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__RunIII2024Summer24NanoAODv15-150X_mcRun3_2024_realistic_v2-v7__privateProduction__job.root"
]

config.section_("Data")
config.Data.outputPrimaryDataset = base
config.Data.publication = False
config.Data.splitting   = "EventBased"
config.Data.unitsPerJob = 1

config.section_("Site")

config.JobType.scriptArgs  = [
    "script=ProduceDYfakePhoton24Tau.sh",
    "events=10000",
    "names=DYfakePhoton24Tau_FullSim.env",
    "submission_tag={}".format(submission_tag),

#--------------------------Edit Below--------------------------
    "stageout_dir=YOUR_DIR/2024/tau"  # Directory inside htozg-dy-privatemc
]
config.Data.totalUnits  = 10000          # Number of CRAB jobs
config.Site.storageSite = "T3_KR_KNU"    # Storage site where you have write permission
config.General.transferOutputs = False
config.General.transferLogs = False
