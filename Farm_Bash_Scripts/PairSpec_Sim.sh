#! /bin/bash

### Stephen Kay, University of York
### 26/05/23
### stephen.kay@york.ac.uk
### A script to execute a series of simulations for the far backward pair spectrometer
### Input args are - NumFiles NumEventsPerFile Egamma_start (optional) Egamma_end (optional)
### This file creates and submits the jobs

SimDir="/group/eic/users/${USER}/ePIC/eic-shell-23p12-stable"
echo "Running as ${USER}"
echo "Assuming simulation directory - ${SimDir}"
if [ ! -d $SimDir ]; then   
    echo "!!! WARNING !!!"
    echo "!!! $SimDir - Does not exist - Double check pathing and try again !!!"
    echo "!!! WARNNING !!!"
    exit 1
fi

NumFiles=$1 # First arg is the number of files to run
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
re='^[0-9]+$'
if [[ -z "$3" ]]; then
    Egamma_start=10
    echo "Egamma_start not specified, defaulting to 10"
else
    Egamma_start=$3
    if ! [[ $Egamma_start =~ $re ]] ; then # Check it's an integer
	echo "!!! EGamma_start is not an integer !!!" >&2; exit 4
    fi
    if (( $Egamma_start > 25 )); then # If Egamma start is too high, set it to 25
	Egamma_start=25
    fi	
fi

# Check if an argument was provided for Egamma_end, if not, set 10
if [[ -z "$4" ]]; then
    Egamma_end=10
    echo "Egamma_end not specified, defaulting to 10"
else
    Egamma_end=$4
    if ! [[ $Egamma_end =~ $re ]] ; then # Check it's an integer
	echo "!!! EGamma_end is not an integer !!!" >&2; exit 5
    fi
    if (( $Egamma_end > 25 )); then # If Egamma end is too high, set it to 25
	Egamma_end=25
    fi	
fi

if [[ -z "$5" ]]; then
    SpagCal="False"
    echo "SpagCal argument not specified, assuming false and running homogeneous calorimeter simulation"
else
    SpagCal=$5
fi

# Standardise capitlisation of true/false statement, catch any expected/relevant cases and standardise them
if [[ $SpagCal == "TRUE" || $SpagCal == "True" || $SpagCal == "true" ]]; then
    SpagCal="True"
    Fiber_Size=$(sed -n 7p ${SimDir}/epic/compact/far_backward/lumi/spec_scifi_cal.xml | sed -e 's/[^0-9]/ /g' | sed -e 's/^ *//g' | sed -e 's/ *$//g' | sed 's/ /p/g')
    Mod_Size=$(sed -n 8p ${SimDir}/epic/compact/far_backward/lumi/spec_scifi_cal.xml | sed -e 's/[^0-9]/ /g' | sed -e 's/^ *//g' | sed -e 's/ *$//g' | sed 's/ /p/g')
elif [[ $SpagCal == "FALSE" || $SpagCal == "False" || $SpagCal == "false" ]]; then
    SpagCal="False"
fi
# Check gun is either true or false, if not, just set it to false
if [[ $SpagCal != "True" && $SpagCal != "False" ]]; then
    SpagCal="False"
    echo "SpagCal (arg 5) not supplied as true or false, defaulting to False. Enter True/False to enable/disable gun based event generation."
fi

echo; echo; echo "!!!!! NOTICE !!!!!"; echo "For now, the outputs generated by jobs from this script will go to a directory under /volatile, change this if you want to keep the files for longer!"; echo "!!!!! NOTICE !!!!!"; echo; echo;
if [ ! -d "/volatile/eic/${USER}" ]; then
    read -p "It looks like you don't have a directory in /volatile/eic, make one? <Y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
	echo "Making a directory for you in /volatile/eic"
	mkdir "/volatile/eic/${USER}"
    else
	echo "If I don't make the directory, I won't have anywhere to output files!"
	echo "Ending here, modify the script and change the directories/paths if you actually want to run this script!"
	exit 4
    fi
fi

OutputPath="/volatile/eic/${USER}/FarBackward_Det_Sim"
if [ ! -d $OutputPath ]; then
    echo "It looks like the output path doesn't exist."
    echo "The script thinks this should be - ${OutputPath}"
    read -p "Make this directory? <Y/N> " prompt2
    if [[ $prompt2 == "y" || $prompt2 == "Y" || $prompt2 == "yes" || $prompt2 == "Yes" ]]; then
	echo "Making directory - ${OutputPath}"
	mkdir $OutputPath
    else
	echo "If I don't make the directory, I won't have anywhere to output files!"
	echo "Ending here, modify the script and change the directories/paths if you actually want to run this script!"
	exit 5
    fi
fi
Timestamp=$(date +'%d_%m_%Y')
Workflow="ePIC_PairSpecSim_${USER}_${Timestamp}" # Change this as desired
export EICSHELL=${SimDir}/eic-shell
Disk_Space=$(( (($NumEvents +(5000/2) ) /5000) +1 )) # Request disk space depending upon number of simulated events requested, always round up to nearest integer value of GB, add 1 GB at end for safety too
for (( i=1; i<=$NumFiles; i++ ))
do
    if [[ $SpagCal == "True" ]]; then
	#Output_tmp="$OutputPath/PairSpecSim_SpagCal_${i}_${NumEvents}_${Egamma_start/./p}_${Egamma_end/./p}"
	Output_tmp="$OutputPath/PairSpecSim_SpagCal_${Fiber_Size}mmFiber_${Mod_Size}mmMod_${FileNum}_${NumEvents}_${Egamma_start/./p}_${Egamma_end/./p}"
    else
	Output_tmp="$OutputPath/PairSpecSim_${i}_${NumEvents}_${Egamma_start/./p}_${Egamma_end/./p}"
    fi
 
    if [ ! -d "${Output_tmp}" ]; then
	mkdir $Output_tmp
    else
	if [ "$(ls -A $Output_tmp)" ]; then # If directory is NOT empty, prompt a warning
	    echo "!!!!! Warning, ${Output_tmp} directory exists and is not empty! Files may be overwritten! !!!!!"
	fi
    fi
    batch="${SimDir}/ePIC_PairSpec_Sim/Farm_Bash_Scripts/FBPairSpec_Sim_${i}_${NumEvents}_${Egamma_start}_${Egamma_end}.txt"
    echo "Running ${batch}"
    cp /dev/null ${batch}
    echo "PROJECT: eic" >> ${batch}
    echo "TRACK: analysis" >> ${batch}    
    #echo "TRACK: debug" >> ${batch}
    echo "JOBNAME: FBPairSpec_Sim_${i}_${NumEvents}_${Egamma_start}_${Egamma_end}" >> ${batch}
    if  [[ $NumEvents -ge 15000 ]]; then # If over 15k events per file, request 6 GB per job
     	echo "MEMORY: 6000 MB" >> ${batch}
    else
     	echo "MEMORY: 4000 MB" >> ${batch}
    fi
    echo "DISK_SPACE: ${Disk_Space} GB" >> ${batch} # Simulation output is the largest hog for this, request 1GB for 5k events simulated - See calculation before the for loop
    echo "CPU: 1" >> ${batch}
    echo "TIME: 1440" >> ${batch} # 1440 minutes -> 1 day
    if [[ $SpagCal == "True" ]]; then
    	echo "COMMAND:${SimDir}/ePIC_PairSpec_Sim/Farm_Bash_Scripts/PairSpec_Sim_Job.sh ${i} ${NumEvents} ${Egamma_start} ${Egamma_end} ${SpagCal}" >> ${batch}
    else
    	echo "COMMAND:${SimDir}/ePIC_PairSpec_Sim/Farm_Bash_Scripts/PairSpec_Sim_Job.sh ${i} ${NumEvents} ${Egamma_start} ${Egamma_end}" >> ${batch}
    	#echo "COMMAND:${SimDir}/ePIC_PairSpec_Sim/Farm_Bash_Scripts/PairSpec_Sim_Job_Test.sh ${i} ${NumEvents} ${Egamma_start} ${Egamma_end}" >> ${batch}
    fi
    echo "MAIL: ${USER}@jlab.org" >> ${batch}
    echo "Submitting batch"
    eval "swif2 add-jsub ${Workflow} -script ${batch} 2>/dev/null"
    echo " "
    sleep 2
    rm ${batch}
done

eval 'swif2 run ${Workflow}'

exit 0
