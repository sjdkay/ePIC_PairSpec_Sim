#! /bin/bash

### Stephen Kay, University of York
### 26/05/23
### stephen.kay@york.ac.uk
### A script to execute an individual simulation for the far backward pair spectrometer
### Input args are - FileNum NumEvents Egamma_start (optional) Egamma_end (optional) SpagCal (optional)
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

FileNum=$1 # First arg is the number of files to run
if [[ -z "$1" ]]; then
    echo "I need a number of files to run!"
    echo "Please provide a number of files to run as the first argument"
    exit 2
fi
NumEvents=$2 # Second argument is an output file name
if [[ -z "$2" ]]; then
    echo "I need a number of events to generate per file!"
    echo "Please provide a number of event to generate per file as the second argument"
    exit 3
fi

# Check if an argument was provided for Egamma_start, if not, set 10
if [[ -z "$3" ]]; then
    Egamma_start=10
    echo "Egamma_start not specified, defaulting to 10"
else
    Egamma_start=$3
fi

# Check if an argument was provided for Egamma_end, if not, set 10
if [[ -z "$4" ]]; then
    Egamma_end=10
    echo "Egamma_end not specified, defaulting to 10"
else
    Egamma_end=$4
fi

# Change output path as desired
OutputPath="/volatile/eic/${USER}/FarBackward_Det_Sim"
export Output_tmp="$OutputPath/PairSpecSim_${FileNum}_${NumEvents}_${Egamma_start/./p}_${Egamma_end/./p}"
if [ ! -d "${Output_tmp}" ]; then # Add this in this script too so it can be run interactively
    mkdir $Output_tmp
else
    if [ "$(ls -A $Output_tmp)" ]; then # If directory is NOT empty, prompt a warning
	if [[ "${HOSTNAME}" == *"ifarm"* ]]; then # Only print this warning if running interactively
	    echo "!!!!! Warning, ${Output_tmp} directory exists and is not empty! Files may be overwritten! !!!!!"
	fi
    fi
fi

export EICSHELL=${SimDir}/eic-shell
cd ${SimDir}
cat <<EOF | $EICSHELL
echo "Printing current path"
pwd
echo ""
echo "ls of volatile"
echo ""
ls -lrth /volatile/
echo ""
echo "ls of /volatile/eic/sjdkay/"
echo ""
ls -lrth /volatile/eic/sjdkay/
echo ""
echo "ls of /group/eic/users/sjdkay/"
ls -lrth /group/eic/users/sjdkay/
echo ""
echo "ls of /group/eic/users/sjdkay/ePIC/eic-shell-23p12-stable"
ls -lrth /group/eic/users/sjdkay/ePIC/eic-shell-23p12-stable
echo ""
echo "EIC Shell Prefix variable"
echo "${EIC_SHELL_PREFIX}"
echo ""
echo "SINGULARITY_BINDPATH variable"
echo "${SINGULARITY_BINDPATH}"
echo ""
echo "SimDir variable"
echo "${SimDir}"
echo ""
echo "ls of SimDir path"
ls -lrth ${SimDir}
echo""
echo "Output path variable"
echo "${OutputPath}"
echo ""
echo "Output tmp variable"
echo "${Output_tmp}"
echo ""
EOF

exit 0
