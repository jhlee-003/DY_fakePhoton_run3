# Based on the central 2024 electron DY fragment plus the Run 3 fake-photon and dilepton filters.
# https://cms-pdmv-prod.web.cern.ch/mcm/public/restapi/requests/get_fragment/GEN-RunIII2024Summer24wmLHEGS-00057

import FWCore.ParameterSet.Config as cms


externalLHEProducer = cms.EDProducer(
    "ExternalLHEProducer",
    args=cms.vstring(
        "/cvmfs/cms.cern.ch/phys_generator/gridpacks/PdmV/RunIII2024Summer24/MadGraph5_aMCatNLO/DY/"
        "DYto2L-2Jets_Bin-MLL-50_amcatnloFXFX-pythia8_slc7_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz"
    ),
    nEvents=cms.untracked.uint32(5000),
    numberOfParameters=cms.uint32(1),
    outputFile=cms.string("cmsgrid_final.lhe"),
    scriptName=cms.FileInPath(
        "GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh"
    ),
    generateConcurrently=cms.untracked.bool(False),
)


from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunesRun3ECM13p6TeV.PythiaCP5Settings_cfi import *
from Configuration.Generator.Pythia8aMCatNLOSettings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *


generator = cms.EDFilter(
    "Pythia8ConcurrentHadronizerFilter",
    maxEventsToPrint=cms.untracked.int32(1),
    pythiaPylistVerbosity=cms.untracked.int32(1),
    pythiaHepMCVerbosity=cms.untracked.bool(False),
    comEnergy=cms.double(13600.0),
    PythiaParameters=cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CP5SettingsBlock,
        pythia8aMCatNLOSettingsBlock,
        pythia8PSweightsSettingsBlock,
        processParameters=cms.vstring(
            "JetMatching:setMad = off",
            "JetMatching:scheme = 1",
            "JetMatching:merge = on",
            "JetMatching:jetAlgorithm = 2",
            "JetMatching:etaJetMax = 999.",
            "JetMatching:coneRadius = 1.",
            "JetMatching:slowJetPower = 1",
            "JetMatching:doFxFx = on",
            "JetMatching:qCut = 30.",
            "JetMatching:qCutME = 10.",
            "JetMatching:nQmatch = 5",
            "JetMatching:nJetMax = 2",
            "TimeShower:mMaxGamma = 4.0",
            "BeamRemnants:primordialKThard=2.48",
        ),
        parameterSets=cms.vstring(
            "pythia8CommonSettings",
            "pythia8CP5Settings",
            "pythia8aMCatNLOSettings",
            "processParameters",
            "pythia8PSweightsSettings",
        ),
    ),
)


lheGenericFilter = cms.EDFilter(
    "LHEGenericFilter",
    src=cms.InputTag("externalLHEProducer"),
    NumRequired=cms.int32(0),
    ParticleID=cms.vint32(11),
    AcceptLogic=cms.string("GT"),
)


# Require a stable photon with pT > 5 GeV whose direct mother is a pi0 or eta.
fakePhotonFilter = cms.EDFilter(
    "PythiaFilterMultiMother",
    ParticleID=cms.untracked.int32(22),
    Status=cms.untracked.int32(1),
    MinPt=cms.untracked.double(5.0),
    MotherIDs=cms.untracked.vint32(111, 221),
)


# Require an opposite-sign electron/muon pair after hadronization.
dileptonPairFilter = cms.EDFilter(
    "MCParticlePairFilter",
    ParticleID1=cms.untracked.vint32(11, 13),
    ParticleID2=cms.untracked.vint32(11, 13),
    ParticleCharge=cms.untracked.int32(-1),
    MinPt=cms.untracked.vdouble(-1.0, -1.0),
    MinP=cms.untracked.vdouble(-1.0, -1.0),
    MinEta=cms.untracked.vdouble(-999.0, -999.0),
    MaxEta=cms.untracked.vdouble(999.0, 999.0),
    Status=cms.untracked.vint32(0, 0),
    MinInvMass=cms.untracked.double(-1.0),
    MaxInvMass=cms.untracked.double(1.0e9),
    MinDeltaPhi=cms.untracked.double(-1.0),
    MaxDeltaPhi=cms.untracked.double(10.0),
    MinDeltaR=cms.untracked.double(-1.0),
    MaxDeltaR=cms.untracked.double(1.0e9),
)


ProductionFilterSequence = cms.Sequence(
    lheGenericFilter * generator * dileptonPairFilter * fakePhotonFilter
)
