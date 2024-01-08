#ifndef CAL_H
#define CAL_H

#include <algorithm>
#include <bitset>

#include <TH2D.h>
#include <TProfile.h>
#include <TFile.h>
#include <TTree.h>
#include <TLorentzVector.h>
#include <THashList.h>

#include <edm4hep/MCParticle.h>
#include <edm4hep/SimTrackerHit.h>
#include <edm4hep/SimCalorimeterHit.h>
#include <edm4hep/RawCalorimeterHit.h>

#include <edm4eic/Cluster.h>
#include <edm4eic/RawCalorimeterHit.h>
#include <edm4eic/ProtoCluster.h>

#include <services/geometry/dd4hep/JDD4hep_service.h>

#include "constants.h"
#include "variables.h"
#include "histogramManager.h"

using namespace std;
using namespace histogramManager;

class CALAnalysis {

  public:

  CALAnalysis();

  void Prepare( 
      std::vector<const edm4hep::SimCalorimeterHit*> &CALHits, 
      std::vector<const edm4hep::RawCalorimeterHit*> &CALadc, 
      std::vector<const edm4eic::CalorimeterHit*> &CALrecHits,
      std::vector<const edm4eic::ProtoCluster*> &CALprotoClusters,
      std::vector<const edm4eic::Cluster*> &CALClusters,
      std::shared_ptr<JDD4hep_service> geoSvc );

  void LoadCalibration();
  void FillTrees();
  void FillDiagnostics();
  void FillAcceptances();
  void CollectGoodClusters();

  TH2D *m_calibration;
  std::vector<edm4eic::Cluster> m_GoodClusters; // our list of corrected clusters

  std::vector<const edm4hep::SimCalorimeterHit*> m_CALhits;
  std::vector<const edm4hep::RawCalorimeterHit*> m_CALadc;
  std::vector<const edm4eic::CalorimeterHit*> m_CALrecHits;
  std::vector<const edm4eic::ProtoCluster*> m_CALprotoClusters;
  std::vector<const edm4eic::Cluster*> m_CALclusters;

  double m_EtopTotal = 0.0;
  double m_EbotTotal = 0.0;

  protected:
    std::shared_ptr<JDD4hep_service> m_geoSvc;
};
#endif