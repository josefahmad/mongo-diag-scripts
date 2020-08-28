#!/bin/bash
# USAGE: stacks.sh CONNSTRING PID

set -e

THRESHOLD_ACTIVE_CONNS=500

PID=$1
CONNSTRING=$2

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

while :
do
    wait_for_trigger
done
