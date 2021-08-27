#!/bin/bash
#
# This plugin checks the used space on docker-storage.
# Either the actual datastore or the metadata-store. This is controlled by the parameter -d. See -h
#
# This plugin is placed on the docker-node and executed using NRPE
#
# Freddie Brandt 2016-05-20
#
#


#################
### Functions ###
#################
function help {
	echo -e "Plugin to check available space on docker-storage"
	echo -e "\t-d\tDevice < storage | metadata >"
	echo -e "\t-w\tWarning level (percent)"
	echo -e "\t-c\tCritical level (percent)"
	echo
	echo -e "Example: $0 -d storage -w 80 -c 90"
	exit 0
}


function checkdocker {
	# First parameter is either Available or Total
	if [ $device == "storage" ]; then
		devicestring="Data Space"
	elif [ $device == "metadata" ]; then
		devicestring="Metadata Space"
	else
		echo "No device found. Check your options"
		exit 2
	fi

	IFS=$'\n'
	for i in $(/usr/bin/docker info 2>/dev/null | grep "$devicestring $1" | cut -d ' ' -f 5-6); do
		UNIT=$(echo "$i" | cut -d ' ' -f 2)
		FIGURES=$(echo "$i" | cut -d ' ' -f 1 | cut -d '.' -f 1)

		case $UNIT in
			MB)
				MULTIPLIER=1048576
				;;
			GB)
				MULTIPLIER=1073741824
				;;
		esac

		BYTES=$(echo "$FIGURES*$MULTIPLIER" | bc)
		echo $BYTES
	done
}



############
### init ###
############
# Getting parameters:
while getopts "d:w:c:h" OPT; do
	case $OPT in
		"d") device=$OPTARG;;
		"w") warning=$OPTARG;;
		"c") critical=$OPTARG;;
		"h") help;;
	esac
done

#####################
### Sanity-checks ###
#####################
# Checking parameters:
( [ "$warning" == "" ] || [ "$critical" == "" ] ) && echo "ERROR: You must specify warning and critical levels" && help
( [ ! "$device" == "storage" ] && [ ! "$device" == "metadata" ] ) && echo "ERROR: You must specify the device to be checked ('storage' or 'metadata')" && help
[[ "$warning" -ge  "$critical" ]] && echo "ERROR: Critical level must be highter than warning level" && help


#####################
### Perform check ###
#####################
bytesused=$(checkdocker Used)
bytestotal=$(checkdocker Total)
pctused=$(echo "$bytesused/$bytestotal*100" | bc -l | cut -d '.' -f1)
byteswarning=$(echo "$warning/100*$bytestotal" | bc -l | cut -d '.' -f1)
bytescritical=$(echo "$critical/100*$bytestotal" | bc -l | cut -d '.' -f1)
 echo $warning
 echo $critical
 echo $bytesused
 echo $bytestotal
 echo $pctused
 echo $byteswarning
 echo $bytescritical
#exit 0

##################
### Get result ###
##################
# Comparing the result and setting the correct level
if [[ $bytesused -ge $bytescritical ]]; then
        msg="CRITICAL"
        status=2
else if [[ $bytesused -ge $byteswarning ]]; then
        msg="WARNING"
        status=1
     else
        msg="OK"
        status=0
     fi
fi

############################
### Printing the results ###
############################
echo "$msg - ${device^^} used space=$bytesused ($pctused%) | 'Disk-used'=$bytesused;'Disk-warn'=$byteswarning;'Disk-crit'=$bytescritical;'Disk-size'=$bytestotal"
exit $status