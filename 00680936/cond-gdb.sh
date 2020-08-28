#!/bin/bash

# USAGE: cond-gdb.sh MONGODB_CONN_STRING_URI PID

#set -e

THRESHOLD_ACTIVE_CONNS=500

MONGODB_CONN_STRING_URI=$1
PID=$2

process_trigger() {
    active_conns=$(mongo $MONGODB_CONN_STRING_URI --quiet --eval 'db.serverStatus().connections.active')

    if [[ $? != 0 ]]; then
        echo "[$(date -u)] failed to connect to the server at $MONGODB_CONN_STRING_URI, is the server running?"
	sleep 1
    else
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
    fi
}

if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 MONGODB_CONN_STRING_URI PID"
    echo "Example:"
    echo "  $0 \"mongodb://user:password@localhost:27017\" \$(pidof mongod)"
    exit
fi

echo "Host: $(hostname -f), PID: $PID"

while :
do
    process_trigger
done
