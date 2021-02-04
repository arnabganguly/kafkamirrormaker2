#!/bin/bash

# Parameters:
# For basic connect setup
# 1. bootstrapServers - Bootstrap server details for Kafka cluster which will be used by connect
# 2. groupId - To identify all connect worker of a connect cluster
# 3. SourceBootstrapServer - Bootstrap server details of the source cluster
# 

trap "CleanUp" 0 1 2 3 13 15 # EXIT HUP INT QUIT PIPE TERM

readonly SCRIPT_NAME="SetupHdInsightKafkaMirrorMaker2"

log()
{
   echo "$@"
   logger -p user.notice -t $SCRIPT_NAME "$@"
}

err()
{
   echo "$@"
   logger -p user.error -t $SCRIPT_NAME "$@"
}

Help()
{
    echo ""
    echo "Example Usage: $0 -c clusterName -g groupId -b bootstrapServers -z zkHosts"
    echo -e "\t-h  Prints usage note"
    echo -e "\t-g  Group ID to identify Connect cluster workers"
    echo -e "\t-b  Broker details to establish a connection from connect cluster"
    echo -e "\t-s  Bootstrap server details to establish a connection with source cluster"
    exit 0 # Exit script after printing help
}

CleanUp()
{
    exit_status=$?
    log "Set up Kafka connect cluster script exited with exit code $exit_status"
    exit "$exit_status"
}

ValidateParameters()
{
        if [[ -z "${GROUP_ID}" ]]; then
            err "Group ID is required" && exit 1;
        fi

        if [[ -z "${BOOTSTRAP_SERVERS}" ]]; then
            err "Bootstrap servers parameter is required" && exit 1;
        fi
}

#Install JQ to work with json files
InstallJQ()
{
    sudo apt install jq -y
}

#Set up Kafka Connect in distributed mode
SetupConnectCluster()
{
    sudo wget -q "https://hdidevscripts.blob.core.windows.net/confandscritps/$CONNECT_SETUP_SCRIPT" -O  /tmp/$CONNECT_SETUP_SCRIPT

    if [[ $? -ne 0 ]]; then
        err "$CONNECT_SETUP_SCRIPT download failed!" && exit $?
    fi

    sudo chmod +x /tmp/$CONNECT_SETUP_SCRIPT

    if [[ $? -ne 0 ]]; then
        err "Making $CONNECT_SETUP_SCRIPT executable failed" && exit $?
    fi

    sudo /tmp/$CONNECT_SETUP_SCRIPT -g $GROUP_ID -b $BOOTSTRAP_SERVERS

    if [[ $? -ne 0 ]]; then
        err "Connect set up failed!" && exit $?
    fi        
}

#Create MM2 specific conf files if they are not there
CreateConfFilesIfDontExist()
{
    if [[ ! -f "${MM2_CONF_DIR_PATH}/${MM2_MIRROR_SRC}.json"  || ! -f "${MM2_CONF_DIR_PATH}/${MM2_MIRROR_CPC}.json" ]]; then
        log "MM2 conf files don't exist. Copying them from storage account"
        sudo wget -q "https://hdidevscripts.blob.core.windows.net/confandscritps/$MM2_MIRROR_SRC.json" -O  /tmp/$MM2_MIRROR_SRC.json
        if [[ $? -ne 0 ]]; then
            err "$MM2_MIRROR_SRC.json download failed!" && exit $?
        fi

        sudo wget -q "https://hdidevscripts.blob.core.windows.net/confandscritps/mm2_checkpoint_connector.json" -O  /tmp/$MM2_MIRROR_CPC.json
        if [[ $? -ne 0 ]]; then
            err "$MM2_MIRROR_CPC.json download failed!" && exit $?
        fi

        sudo mkdir -p $MM2_CONF_DIR_PATH && sudo cp /tmp/mm2_*.json $MM2_CONF_DIR_PATH

        if [[ $? -ne 0 ]]; then
           err "Copy files to $MM2_CONF_DIR_PATH failed" && exit $?
        else
           log "MM2 conf files are copied to required location: ${MM2_CONF_DIR_PATH}"
        fi
    else 
        log "MM2 conf files are found in required location: ${MM2_CONF_DIR_PATH}"
    fi
}

#Update MM2 required configs
UpdateRequiredconfigs()
{
    exit_code=0
    jq '.["source.cluster.bootstrap.servers"] = $SOURCE_BOOTSTRAP_SERVERS' --arg SOURCE_BOOTSTRAP_SERVERS "$SOURCE_BOOTSTRAP_SERVERS" $MM2_CONF_DIR_PATH/$MM2_MIRROR_SRC.json > tmp.$$.json && mv tmp.$$.json $MM2_CONF_DIR_PATH/$MM2_MIRROR_SRC.json || exit_code=$?
    jq '.["target.cluster.bootstrap.servers"] = $BOOTSTRAP_SERVERS' --arg BOOTSTRAP_SERVERS "$BOOTSTRAP_SERVERS" $MM2_CONF_DIR_PATH/$MM2_MIRROR_SRC.json > tmp.$$.json && mv tmp.$$.json $MM2_CONF_DIR_PATH/$MM2_MIRROR_SRC.json || exit_code=$?

    jq '.["source.cluster.bootstrap.servers"] = $SOURCE_BOOTSTRAP_SERVERS' --arg SOURCE_BOOTSTRAP_SERVERS "$SOURCE_BOOTSTRAP_SERVERS" $MM2_CONF_DIR_PATH/$MM2_MIRROR_CPC.json > tmp.$$.json && mv tmp.$$.json $MM2_CONF_DIR_PATH/$MM2_MIRROR_CPC.json || exit_code=$?
    jq '.["target.cluster.bootstrap.servers"] = $BOOTSTRAP_SERVERS' --arg BOOTSTRAP_SERVERS "$BOOTSTRAP_SERVERS" $MM2_CONF_DIR_PATH/$MM2_MIRROR_CPC.json > tmp.$$.json && mv tmp.$$.json $MM2_CONF_DIR_PATH/$MM2_MIRROR_CPC.json || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then 
       err "Updating required config for MM2 failed!" && exit $exit_code
    fi
}

#Check and wait for REST server to be up
IsConnectorRestServerUp()
{
   maxAttempts=5
   currAttempt=0
   until [ "$currAttempt" -ge "$maxAttempts" ]
   do
      rep=$(curl -f -s -X GET http://localhost:8083)
      status=$?
      log "Connector REST server status $status"
      if [[ "$status" -eq 0 ]]; then 
          break
      fi

      currAttempt=$((currAttempt+1))
      log "Connect REST server is not up. We will retry($currAttempt/$maxAttempts)!"
      sleep 12
   done

   if [[ $currAttempt -ge $maxAttempts ]]; then
      err "Connector REST server is not up, no more retries are left, giving up!"
      exit $status
   fi
}

#Start MirrorMaker 2 
StartConnector()
{
    rep=$(curl -f -s -X PUT http://localhost:8083/connectors/$1/config -H "Content-Type: application/json" -d @$MM2_CONF_DIR_PATH/$1.json)
    status="$?"
    log "Connector start response for $1  = $rep"
    if [[ "$status" -ne 0 ]]; then
       err "Failed to start connector $1!"
       exit $status
    fi
}

###  Main  ###

log "Set up kafka MM2 cluster properties"

# get script parameters
while getopts "g::b::s::h" opt
do
    case "$opt" in        
        g) GROUP_ID="$OPTARG" ;;
        b) BOOTSTRAP_SERVERS="$OPTARG" ;;
        s) SOURCE_BOOTSTRAP_SERVERS="$OPTARG" ;;
        h)
            Help
            exit 0
            ;;
    esac
done

log "Group ID=$GROUP_ID"
log "Bootstrap Servers (Target)=$BOOTSTRAP_SERVERS"
log "Source bootstrap server=$SOURCE_BOOTSTRAP_SERVERS"

CONNECT_SETUP_SCRIPT="SetupConnectCluster.sh"
MM2_CONF_DIR_PATH="/usr/hdp/current/kafka-broker/conf/mm2"
MM2_MIRROR_SRC="mm2_source_connector"
MM2_MIRROR_CPC="mm2_checkpoint_connector"

# check script parameters 
ValidateParameters

# Install JQ
InstallJQ

# Plain vanilla Connector related
SetupConnectCluster

log "Kafka Connect set up is completed successfully!"

# MM2 specifc
CreateConfFilesIfDontExist
UpdateRequiredconfigs
IsConnectorRestServerUp
StartConnector "${MM2_MIRROR_SRC}"
StartConnector "${MM2_MIRROR_CPC}"

log "Kafka MM2 set up is completed successfully!"

exit 0
