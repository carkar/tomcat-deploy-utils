#!/bin/bash

#
# Remote tomcat deploy script
#
# 1. Scps a web archive to a the remote server.
# 2. Stop the remote tomcat.
# 3. Copies to war file to tomcat webapps.
# 4. Starts the remote tomcat.
# 

EXPECTED_ARGS=3
NOW=$(date +"%Y%m%d%H%M%S")

if [ $# -lt $EXPECTED_ARGS ]
then
  echo "Usage: `basename $0` <server> <file> <context>"
  exit $E_BADARGS
fi

CONTEXT=$3
FILE=$2
SERVER=$1

REMOTE_FILE=/tmp/$CONTEXT-$NOW.war
REMOTE_WEBAPPS=/opt/tomcat/current/webapps
REMOTE_WAR="$REMOTE_WEBAPPS/$CONTEXT.war"
REMOTE_CONTEXT="$REMOTE_WEBAPPS/$CONTEXT"
START_TOMCAT="sudo /etc/init.d/tomcat start"
STOP_TOMCAT="sudo /etc/init.d/tomcat stop"

# Copy local war to remote machine
copy_file() {
	log "Copying $FILE to $SERVER:$REMOTE_FILE"
	scp $FILE $SERVER:$REMOTE_FILE
}

# Stops tomcat on remote machine
stop_server() {
	log "Stopping remote tomcat"
	ssh $SERVER $STOP_TOMCAT
	sleep 10
	ssh $SERVER "kill -9 `ps ux | awk '/java/ && /tomcat/ && !/awk/ {print $2}'`"
}

# Start tomcat on remote machine
start_server() {
	log "Starting remote tomcat"
	ssh $SERVER $START_TOMCAT
}

# Copy remote temporary file to deployment path
deploy_file() {
	log "Deleting old version of $CONTEXT"
	ssh $SERVER sudo rm -rf $REMOTE_WAR
	ssh $SERVER sudo rm -rf $REMOTE_CONTEXT

	log "Copying temporary file to $REMOTE_WAR"
	ssh $SERVER sudo mv $REMOTE_FILE $REMOTE_WAR
}

log_deployment() {
    ssh $SERVER 'echo "Deployment was started at `date`" >> ~/deploy_log.txt'
}

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1"
}

log "Deploying $FILE to $SERVER/$CONTEXT"

log_deployment
copy_file
stop_server
deploy_file
start_server

log "Done deploying."
