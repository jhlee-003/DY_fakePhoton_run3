from WMCore.Configuration import Configuration
config = Configuration()

import os
work_area = "crab_projects"
base = "DY_FakePhoton_Run3_22_FullSim"

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
    "config/DYfakePhoton22_FullSim.env", 
    "config/DYfakePhoton22_fragment.py", 
    "ProduceDYfakePhoton22.sh"
]
config.JobType.outputFiles = [
    "DYto2L-2Jets_MLL-50_TuneCP5_13p6TeV_amcatnloFXFX-pythia8__Run3Summer22_NanoAODv12-130X_mcRun3_2022_realistic_v5__privateProduction__job.root"
]

config.JobType.scriptArgs  = [
    "script=ProduceDYfakePhoton22.sh", 
    "events=10000", 
    "names=DYfakePhoton22_FullSim.env"
]

config.section_("Data")
config.Data.outputPrimaryDataset = base
config.Data.publication = False
config.Data.splitting   = "EventBased"
config.Data.unitsPerJob = 1

config.section_("Site")

#-----------Edit Below------------
config.Data.totalUnits  = 10             # Number of CRAB jobs
config.Site.storageSite = "T3_KR_KNU"    # Storage site where you have write permission (Required syntactically by CRAB)
config.General.transferOutputs = False   # Change to `True` if you want to transfer your output to your storage site
config.General.transferLogs = False      # Change to `True` if you want to transfer the log to your storage site
