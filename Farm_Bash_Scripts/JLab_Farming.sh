#! /bin/bash

### Stephen Kay, University of York
### 22/04/24
### stephen.kay@york.ac.uk
### A script to create and submit jobs to the JLab farm.
### As is, takes 4 arguments, number of files, number of events per file, then two example arguments.
### Arg3/Arg4 could be something you feed your specific script, add or remove as needed.

SimDir="/group/eic/users/${USER}/ePIC/" # Put in the path of your directory here (where your eic-shell is)
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

if [[ -z "$3" ]]; then # Third argument - something passed to the script, default to 10
    Arg3=10
    echo "Arg3 not specified, defaulting to 10"
fi

# Check if a fourth argument is provided, pass something to script. Default to 10
if [[ -z "$4" ]]; then
    Arg4=10
    echo "Arg4 not specified, defaulting to 10"
fi

# For now, output to /volatile. Change if you want to keep files longer
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

OutputPath="/volatile/eic/${USER}" # Specify your output path
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
Workflow="ePIC_Sim_${USER}_${Timestamp}" # Change this as desired
export EICSHELL=${SimDir}/eic-shell # Must point to where your eic-shell is!
# Define a disk space request. Change depending upon your needs. 
Disk_Space=$(( (($NumEvents +(5000/2) ) /5000) +1 )) # Request disk space depending upon number of simulated events requested, always round up to nearest integer value of GB, add 1 GB at end for safety too
for (( i=1; i<=$NumFiles; i++ ))
do
    Output_tmp="$OutputPath/Sim_${i}_${NumEvents}_${Arg3/./p}_${Arg4/./p}"
    if [ ! -d "${Output_tmp}" ]; then
	mkdir $Output_tmp
    else
	if [ "$(ls -A $Output_tmp)" ]; then # If directory is NOT empty, prompt a warning
	    echo "!!!!! Warning, ${Output_tmp} directory exists and is not empty! Files may be overwritten! !!!!!"
	fi
    fi
    batch="${SimDir}/Sim_${i}_${NumEvents}_${Arg3}_${Arg4}.txt" # This is where the job file will be created, change as desired
    echo "Running ${batch}"
    cp /dev/null ${batch}
    echo "PROJECT: eic" >> ${batch}
    echo "TRACK: analysis" >> ${batch}    
    echo "JOBNAME: ePIC_Sim_${i}_${NumEvents}_${Arg3}_${Arg4}" >> ${batch}
    if  [[ $NumEvents -ge 15000 ]]; then # If over 15k events per file, request 6 GB per job
     	echo "MEMORY: 6000 MB" >> ${batch}
    else
     	echo "MEMORY: 4000 MB" >> ${batch}
    fi
    echo "DISK_SPACE: ${Disk_Space} GB" >> ${batch} # Simulation output is the largest hog for this, request 1GB for 5k events simulated - See calculation before the for loop
    echo "CPU: 1" >> ${batch}
    echo "TIME: 1440" >> ${batch} # 1440 minutes -> 1 day
    # The line below is the "guts" of this script. This is the script or job we will actually run on the farm node. Change the pathing to your script as needed. Submit the args as needed.
    echo "COMMAND:${SimDir}/JLab_Farming_Job.sh ${i} ${NumEvents} ${Arg3} ${Arg4}" >> ${batch}
    echo "MAIL: ${USER}@jlab.org" >> ${batch} # Modify as desired
    echo "Submitting batch job"
    eval "swif2 add-jsub ${Workflow} -script ${batch} 2>/dev/null" # Add our created job to the swif2 workflow
    echo " "
    sleep 2
    rm ${batch} # Remove the job script after submission
done

eval 'swif2 run ${Workflow}'

exit 0
