#!/bin/bash

# Parameters:
# For basic connect setup
# 1. kafkaClusterName - Kafka Cluster Name  
# 1. bootstrapServers - Bootstrap server details for Kafka cluster which will be used by connect
# 2. zkHosts - Zookeeper server of the Kafka cluster
# 3. groupId - To identify all connect worker of a connect cluster
# 

trap "CleanUp" 0 1 2 3 13 15 # EXIT HUP INT QUIT PIPE TERM

readonly SCRIPT_NAME=$(basename $0)

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

UpdateConnectDistributedProperties()
{
    #Replace bootstrap server value
    sudo sed -i "s/\(bootstrap.servers=\).*/\1${BOOTSTRAP_SERVERS}/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Replace Group.ID value
    sudo sed -i "s/\(group.id=\).*/\1${GROUP_ID}/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Replace offset storage topic related properties
    OFFSET_TOPIC_NAME="offset_$GROUP_ID"
    sudo sed -i "s/\(offset.storage.topic=\).*/\1${OFFSET_TOPIC_NAME}/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/\(offset.storage.replication.factor=\).*/\13/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/\(offset.storage.partitions=\).*/\14/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/^#\(offset.storage.partitions=.*\)/\1/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Replace config  storage topic related properties
    CONFIG_TOPIC_NAME="config_$GROUP_ID"
    sudo sed -i "s/\(config.storage.topic=\).*/\1${CONFIG_TOPIC_NAME}/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/\(config.storage.replication.factor=\).*/\13/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties    

    #Replace status  storage topic related properties
    STATUS_TOPIC_NAME="storage_$GROUP_ID"
    sudo sed -i "s/\(status.storage.topic=\).*/\1${STATUS_TOPIC_NAME}/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/\(status.storage.replication.factor=\).*/\13/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/\(status.storage.partitions=\).*/\14/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/^#\(status.storage.partitions=.*\)/\1/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Set offset flush interval value
    sudo sed -i "s/\(offset.flush.interval.ms=\).*/\110000/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Set rest port value
    sudo sed -i "s/\(rest.port=\).*/\18083/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "s/^#\(rest.port=.*\).*/\1/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties

    #Set plugin path
    sudo sed -i "/^plugin.path=.*/d" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
    sudo sed -i "$ a plugin.path=/usr/hdp/current/kafka-broker/plugins/" /usr/hdp/current/kafka-broker/conf/connect-distributed.properties
}


#Start Kafka connect in distributed mode in the background on the edge node
StartKafkaConnectInDistributedMode()
{
    nohup sudo /usr/hdp/current/kafka-broker/bin/connect-distributed.sh  /usr/hdp/current/kafka-broker/conf/connect-distributed.properties &> /var/log/syslog &
}

###  Main  ###

log "Set up kafka connect cluster properties"

# get script parameters
while getopts "g::b::h" opt
do
    case "$opt" in
        g) GROUP_ID="$OPTARG" ;;
        b) BOOTSTRAP_SERVERS="$OPTARG" ;;
        h)
            Help
            exit 0
            ;;
    esac
done

log "Group ID=$GROUP_ID"
log "Bootstrap Servers=$BOOTSTRAP_SERVERS"

# check script parameters 
ValidateParameters

UpdateConnectDistributedProperties
StartKafkaConnectInDistributedMode

log "Kafka Connect set up is completed successfully!"
exit 0
