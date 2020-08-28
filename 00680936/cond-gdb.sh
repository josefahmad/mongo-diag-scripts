#!/bin/bash
# USAGE: stacks.sh CONNSTRING PID

set -e

THRESHOLD_ACTIVE_CONNS=500

CONNSTRING=$1
PID=$2

wait_for_trigger() {
    active_conns=$(mongo $CONNSTRING --quiet --eval 'db.serverStatus().connections.active')
    if [ $active_conns -ge $THRESHOLD_ACTIVE_CONNS ]
    then
        echo "[$(date -u)] (serverStatus.connections.active: $active_conns) condition triggered! collecting GDB..."
	gdb -p $PID -batch -ex 'thread apply all bt' > /tmp/gdb-$(hostname -f)-stacks-$(date -u '+%Y-%m-%dT%H-%M-%SZ').txt
        echo "[$(date -u)] (serverStatus.connections.active: $active_conns) waiting for the next triggering period (20s)..."
	sleep 20
    else
    	echo "[$(date -u)] (serverStatus.connections.active: $active_conns) waiting for the next triggering period (1s)..."
	sleep 1
    fi
}

if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 MONGODB_CONN_STRING_URI PID"
    echo "Example:"
    echo "  $0 \"mongodb://user:password@localhost:27017\" \$(pidof mongod)"
    exit
fi

echo "Host: $(hostname -f), PID: $PID"

while :
do
    wait_for_trigger
done
