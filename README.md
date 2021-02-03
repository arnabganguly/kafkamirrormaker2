# Deploy an edge node cluster to a HDInsight cluster with Mirror Maker 2 configured.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmohapatrasambit%2FHDInsightKafkaMirrorMaker2%2Fmaster%2Fazuredeploy.json)  [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https://raw.githubusercontent.com/mohapatrasambit/HDInsightKafkaMirrorMaker2/master/azuredeploy.json)

This template allows you to add an edge node cluster to an existing HDInsight cluster. This will run a custom script action to enable Kafka Mirror Maker 2 on Kafka connect framework. 

The edge node virtual machine size must meet the worker node vm size requirements. The worker node vm size requirements are different from region to region. For more information, see Create HDInsight clusters.

For more information about creating and using edge node, see <a href="https://docs.microsoft.com/azure/hdinsight/hdinsight-apps-use-edge-node">Use empty edge nodes in HDInsight


