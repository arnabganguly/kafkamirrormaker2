# Deploy an edge node cluster to a HDInsight Kafka cluster with MirrorMaker 2 configured with some default settings.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmohapatrasambit%2FHDInsightKafkaMirrorMaker2%2Fmaster%2Fazuredeploy.json)  [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https://raw.githubusercontent.com/mohapatrasambit/HDInsightKafkaMirrorMaker2/master/azuredeploy.json)

This template allows you to add an edge node cluster to an existing HDInsight cluster. This will run a custom script action to enable Kafka MirrorMaker 2 on Kafka connect framework. The script action that will be used with template will need following parameters:
<li> -g :: Group ID to identify Connect cluster workers
<li> -b :: Broker details to establish a connection from connect cluster
<li> -s :: Bootstrap server details to establish a connection with source cluster

Example of parameter:
--g mm2_grp_01 -b targetBroker1:9092,targetBroker2:9092 -s SourceBroker-1-DNS/IP:9092,SourceBroker-1-DNS/IP:9092

<i>In case of two clusters are running in two peered vNets and advertised listener is used, then source brokers' IPs are required.</i>

For more information on running HDInsight Kafka in vNets, see <a href="https://docs.microsoft.com/en-us/azure/hdinsight/kafka/apache-kafka-connect-vpn-gateway">Connect to Apache Kafka on HDInsight through an Azure Virtual Network </a>

The edge node virtual machine size must meet the worker node vm size requirements. The worker node vm size requirements are different from region to region. For more information, see Create HDInsight clusters.

For more information about creating and using edge node, see <a href="https://docs.microsoft.com/azure/hdinsight/hdinsight-apps-use-edge-node">Use empty edge nodes in HDInsight </a>

<b><i>** This template can be used as a quick start template for onboarding Kafka MM2 on HDInsight Kafka 2.4. But to achieve further granularity on mirroring, one should update configurations to suit their need</i></b>


