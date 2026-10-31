// Creates a machine learning workspace, private endpoints and compute resources
// Compute resources include a GPU cluster, CPU cluster, compute instance and attached private AKS cluster
@description('Prefix for resource names')
param prefix string

@description('Storage Account to create a Data Store')
param storageAccountName string

@description('storage account container name to create datastore')
param containerName string

@description('To get the DNS suffic for Storage Account')
param environmentObject object

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Machine learning workspace name')
param machineLearningName string

@description('Machine learning workspace display name')
param machineLearningFriendlyName string = machineLearningName

@description('Machine learning workspace description')
param machineLearningDescription string

@description('Resource ID of the application insights resource')
param applicationInsightsId string

@description('Resource ID of the container registry resource')
param containerRegistryId string

@description('Resource ID of the key vault resource')
param keyVaultId string

@description('Resource ID of the storage account resource')
param storageAccountId string

// @description('Resource ID of the subnet resource')
// param subnetId string

// @description('Resource ID of the compute subnet')
// param computeSubnetId string

@description('storage account key to create container')
param storageKey string

// @description('Resource ID of the virtual network')
// param virtualNetworkId string

// @description('Machine learning workspace private link endpoint name')
// param machineLearningPleName string

@description('Enable public IP for Azure Machine Learning compute nodes')
param amlComputePublicIp bool = true

@description('VM size for the default compute cluster')
param vmSizeParam string

resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-05-01' = {
  name: machineLearningName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // workspace organization
    friendlyName: machineLearningFriendlyName
    description: machineLearningDescription

    // dependent resources
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    keyVault: keyVaultId
    storageAccount: storageAccountId

    // configuration for workspaces with private link endpoint
    imageBuildCompute: 'cluster001'
    publicNetworkAccess: 'Enabled'
  }
}

// module machineLearningPrivateEndpoint 'machinelearningnetworking.bicep' = {
//   name: 'machineLearningNetworking'
//   scope: resourceGroup()
//   params: {
//     location: location
//     tags: tags
//     virtualNetworkId: virtualNetworkId
//     workspaceArmId: machineLearning.id
//     subnetId: subnetId
//     machineLearningPleName: machineLearningPleName
//   }
// }

module machineLearningCompute 'machinelearningcompute.bicep' = {
  name: 'machineLearningComputes'
  scope: resourceGroup()
  params: {
    machineLearning: machineLearningName
    location: location
    // computeSubnetId:computeSubnetId
    prefix: prefix
    tags: tags
    amlComputePublicIp: amlComputePublicIp
    vmSizeParam: vmSizeParam
  }
  dependsOn: [
    machineLearning
  ]
}

resource dataStore 'Microsoft.MachineLearningServices/workspaces/dataStores@2022-05-01' = {
  name: 'mldatastore_001'
  parent: machineLearning
  properties: {
    accountName: storageAccountName
    containerName: containerName
    credentials: {
      credentialsType: 'AccountKey'
      secrets: {
        key: storageKey
        secretsType: 'AccountKey'
      }
    }
    datastoreType: 'AzureBlob'
    description: ''
    endpoint: environmentObject.suffixes.storage
    serviceDataAccessAuthIdentity: 'WorkspaceSystemAssignedIdentity'
  }
}

module roleassignment 'roleassignment.bicep' = {
  name: 'machineLearningRoleAssignments'
  params: {
    // principalIDML: machineLearning.identity.principalId
    principalIDComInstance: machineLearningCompute.outputs.instanceIdentity
    principalIDMLCompCluster: machineLearningCompute.outputs.clusterIdentity
  }
}

output machineLearningId string = machineLearning.id

