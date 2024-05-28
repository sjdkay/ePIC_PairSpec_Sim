#! /bin/bash

### Stephen Kay, University of York
### 26/05/23
### stephen.kay@york.ac.uk
### A script to execute an individual simulation for the far backward pair spectrometer
### Input args are - NumEvents EBeam HBeam Pos
### Intended to be fed to some swif2 job submission script

SimDir="/group/eic/users/${USER}/ePIC/eic-shell-23p12-stable"
echo "Running as ${USER}"
echo "Assuming simulation directory - ${SimDir}"
if [ ! -d $SimDir ]; then   
    echo "!!! WARNING !!!"
    echo "!!! $SimDir - Does not exist - Double check pathing and try again !!!"
    echo "!!! WARNNING !!!"
    exit 1
fi

NumEvents=$1 # First argument is the number of events to run
if [[ -z "$1" ]]; then
    echo "I need a number of events to generate per file!"
    echo "Please provide a number of event to generate per file as the first argument"
    exit 2
fi
EBeam=$2 # Check if an argument was provided for EBeam
if [[ -z "$2" ]]; then
    echo "I need an electron beam energy!"
    echo "Please provide an electron beam energy as the second argument!"
    exit 3
fi
HBeam=$3 # Check if an argument was provided for EBeam
if [[ -z "$3" ]]; then
    echo "I need a hadron beam energy!"
    echo "Please provide a hadron beam energy as the third argument!"
    exit 4
fi
Pos=$4 # Check if an argument was provided for EBeam
if [[ -z "$4" ]]; then
    echo "I need a position to propagate to!"
    echo "Please provide a position as the fourth argument!"
    exit 5
fi

if [[ $Pos == 22750 ]]; then
    PosName="BPExit"
elif [[ $Pos == 58000 ]]; then
    PosName="Conv"
elif [[ $Pos == 58000 ]]; then
    PosName="AnExit"
else
    PosName="ERROR"
fi

# Change output path as desired
OutputPath="/volatile/eic/${USER}/FarBackward_Det_Sim/Beam_Energy_Combos"

export EICSHELL=${SimDir}/eic-shell
cd ${SimDir}
# Run EIC shell, generate the events, afterburn them, run the simulation, reconstruct the events
cat <<EOF | $EICSHELL
source Init_Env.sh
echo; echo; echo "Generating events."; echo; echo;
cd ${SimDir}/ePIC_PairSpec_Sim/simulations/
root -l -b -q 'lumi_particles.cxx(${NumEvents}, false, false, false, 0.1, ${EBeam},"${OutputPath}/genParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}.hepmc", ${EBeam}, ${HBeam})'
sleep 1
root -b -l -q 'PropagateAndConvert.cxx("${OutputPath}/genParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}.hepmc", "${OutputPath}/genParticles_${PosName}_${EBeam}x${HBeam}_${NumEvents}.hepmc", -${Pos})'
echo; echo; echo "Events generated, propagated and converted, afterburning."; echo; echo;
sleep 1
abconv ${OutputPath}/genParticles_${PosName}_${EBeam}x${HBeam}_${NumEvents}.hepmc --plot-off -o ${OutputPath}/abParticles_PhotonsAt${PosName}_${EBeam}x${HBeam}_${NumEvents}
sleep 1
echo; echo; echo "Events propagated and converted, running simulation."; echo; echo;
npsim -v 4 --inputFiles ${OutputPath}/abParticles_PhotonsAt${PosName}_${EBeam}x${HBeam}_${NumEvents}.hepmc --outputFile ${OutputPath}/${PosName}_${EBeam}x${HBeam}_${NumEvents}_PropThenAB.edm4hep.root --compactFile ${SimDir}/epic/epic_ip6_FB.xml -N ${NumEvents}
sleep 1
EOF

exit 0

# # Run EIC shell, generate the events, afterburn them, run the simulation, reconstruct the events
# # Original version for reference - Testing flipping prop/convert and AB steps 28/05/24
# cat <<EOF | $EICSHELL
# source Init_Env.sh
# echo; echo; echo "Generating events."; echo; echo;
# cd ${SimDir}/ePIC_PairSpec_Sim/simulations/
# root -l -b -q 'lumi_particles.cxx(${NumEvents}, false, false, false, 0.1, ${EBeam},"${OutputPath}/genParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}.hepmc", ${EBeam}, ${HBeam})'
# sleep 1
# abconv ${OutputPath}/genParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}.hepmc --plot-off -o ${OutputPath}/abParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}
# echo; echo; echo "Events generated and afterburned, propagating and converting."; echo; echo;
# sleep 1
# root -b -l -q 'PropagateAndConvert.cxx("${OutputPath}/abParticles_PhotonsAtIP_${EBeam}x${HBeam}_${NumEvents}.hepmc", "${OutputPath}/abParticles_${PosName}_${EBeam}x${HBeam}_${NumEvents}.hepmc", -${Pos})'
# sleep 1
# echo; echo; echo "Events propagated and converted, running simulation."; echo; echo;
# npsim -v 4 --inputFiles ${OutputPath}/abParticles_${PosName}_${EBeam}x${HBeam}_${NumEvents}.hepmc --outputFile ${OutputPath}/${PosName}_${EBeam}x${HBeam}_${NumEvents}.edm4hep.root --compactFile ${SimDir}/epic/epic_ip6_FB.xml -N ${NumEvents}
# sleep 1
# EOF
