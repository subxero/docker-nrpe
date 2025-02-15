#!/bin/sh -e

export HOST_IP="${HOST_IP:-$(/sbin/ip route|awk '/default/ { print $3 }')}"

export ETCD_HOST="${ETCD_HOST:-$HOST_IP}"
export ETCD_PORT="${ETCD_PORT:-4001}"

export CHECK_YODA="${CHECK_YODA:-}"
export CHECK_YODA_HOST="${CHECK_YODA_HOST:-$HOST_IP}"
export MACHINE_ID="${MACHINE_ID:-local}"
export MACHINE_CORES="$(nproc)"

if [ -f "/usr/sbin/nrpe" ]; then
  NRPE_EXEC="/usr/sbin/nrpe"
else
  NRPE_EXEC="/usr/bin/nrpe"
fi


# Add disk plugin
#CHECKDISKS="${CHECKDISKS:-$( ls -d -1 /mnt/* || echo)}"
CHECKDISKS="${CHECKDISKS:-$( df -hT | grep -v -e tmpfs -e  overlay -e Mounted -e aws-ebs -e snap | awk '{print $7}' ) }"
if [ ! -z "$CHECKDISKS" ]; then
    NAGIOS_DRIVES_RAW="$(echo "$CHECKDISKS" | awk -F "[ \t\n,]+"  '{for (driveCnt = 1; driveCnt <= NF; driveCnt++) printf "-p %s ",$driveCnt}')"
    NAGIOS_DRIVES=$(echo "$NAGIOS_DRIVES_RAW" | sed -e 's/ -p\s*$//')
    echo "command[check_disk]=$NAGIOS_PLUGINS_DIR/check_disk -w 20% -c 10% $NAGIOS_DRIVES" | tee $NAGIOS_CONF_DIR/nrpe.d/disk.cfg > /dev/null
fi

#This sets the check_load to adapt the threshold to the number of Cores
echo "command[check_load]=/usr/lib/nagios/plugins/check_load -w `echo \`nproc\`*1 | bc`,`echo \`nproc\`*0.8 | bc`,`echo \`nproc\`*0.8 | bc` -c `echo \`nproc\`*1.5 | bc`,`echo \`nproc\`*1 | bc`,`echo \`nproc\`*1 | bc`" | tee $NAGIOS_CONF_DIR/nrpe.d/load.cfg > /dev/null

# Start NREP Server
$NRPE_EXEC -c $NAGIOS_CONF_DIR/nrpe.cfg -d

# Wait for NRPE Daemon to exit
PID=$(ps -ef | grep -v grep | grep  "${NRPE_EXEC}" | awk '{print $2}')
if [ ! "$PID" ]; then
  echo "Error: Unable to start nrpe daemon..."
  # exit 1
fi
while [ -d /proc/$PID ] && [ -z `grep zombie /proc/$PID/status` ]; do
    echo "NRPE: $PID (running)..."
    sleep 60s
done
echo "NRPE daemon exited. Quitting.."