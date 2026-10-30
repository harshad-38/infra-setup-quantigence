// Execute this main file to configure Azure Machine Learning end-to-end in a moderately secure set up

// Parameters
@minLength(2)
@maxLength(10)
@description('Prefix for all resource names.')
param prefix string

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
param tags object

// @description('Virtual network address prefix')
// param vnetAddressPrefix string

// @description('Training subnet address prefix')
// param trainingSubnetPrefix string

// @description('Scoring subnet address prefix')
// param scoringSubnetPrefix string

// @description('Bastion subnet address prefix')
// param azureBastionSubnetPrefix string

// @description('Deploy a Bastion jumphost to access the network-isolated environment?')
// param deployJumphost bool

// @description('Jumphost virtual machine username')
// param dsvmJumpboxUsername string

// @secure()
// @minLength(8)
// @description('Jumphost virtual machine password')
// param dsvmJumpboxPassword string

@description('Enable public IP for Azure Machine Learning compute nodes')
param amlComputePublicIp bool

@description('VM size for the default compute cluster')
param amlComputeDefaultVmSize string

// Variables
var name = toLower('${prefix}')

// Create a short, unique suffix, that will be unique to each resource group
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 2, 6)

// Virtual network and network security group
module nsg 'modules/azure_ml/nsg.bicep' = { 
  name: 'nsg-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    tags: tags 
    nsgName: 'nsg-${name}-${uniqueSuffix}'
  }
}

// module vnet 'modules/azure_ml/vnet.bicep' = {
//   name: 'vnet-${name}-${uniqueSuffix}-deployment'
//   params: {
//     location: location
//     virtualNetworkName: 'vnet-${name}-${uniqueSuffix}'
//     networkSecurityGroupId: nsg.outputs.networkSecurityGroup
//     vnetAddressPrefix: vnetAddressPrefix
//     trainingSubnetPrefix: trainingSubnetPrefix
//     scoringSubnetPrefix: scoringSubnetPrefix
//     tags: tags
//   }
// }

// Dependent resources for the Azure Machine Learning workspace
module keyvault 'modules/azure_ml/keyvault.bicep' = {
  name: 'kvd-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    keyvaultName: 'kvd-${name}-${uniqueSuffix}'
    // keyvaultPleName: 'ple-${name}-${uniqueSuffix}-kv'
    // subnetId: '${vnet.outputs.id}/subnets/snet-training'
    // virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module storage 'modules/azure_ml/storage.bicep' = {
  name: 'st${name}${uniqueSuffix}-deployment'
  params: {
    location: location
    storageName: 'st${name}${uniqueSuffix}'
    // storagePleBlobName: 'ple-${name}-${uniqueSuffix}-st-blob'
    // storagePleFileName: 'ple-${name}-${uniqueSuffix}-st-file'
    storageSkuName: 'Standard_LRS'
    // subnetId: '${vnet.outputs.id}/subnets/snet-training'
    // virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module containerRegistry 'modules/azure_ml/containerregistry.bicep' = {
  name: 'cr${name}${uniqueSuffix}-deployment'
  params: {
    location: location
    containerRegistryName: 'cr${name}${uniqueSuffix}'
    // containerRegistryPleName: 'ple-${name}-${uniqueSuffix}-cr'
    // subnetId: '${vnet.outputs.id}/subnets/snet-training'
    // virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module applicationInsights 'modules/azure_ml/applicationInsights.bicep' = {  
  name: 'appi-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    applicationInsightsName: 'appi-${name}-${uniqueSuffix}'
    logAnalyticsWorkspaceName: 'ws-${name}-${uniqueSuffix}'
    tags: tags
  }
}

// module dnsResolver 'modules/azure_ml/dnsresolver.bicep' = {
//   name: 'dnsr-${name}-${uniqueSuffix}-deployment'
//   params: {
//     dnsResolverName: 'dnsr-${name}-${uniqueSuffix}'
//     inboundSubnet: 'snet-dns-inbound'
//     location:location
//     tags: tags
//   }
// }

module azuremlWorkspace 'modules/azure_ml/machinelearning.bicep' = {
  name: 'mlw-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    machineLearningName: 'mlw-${name}-${uniqueSuffix}'
    machineLearningFriendlyName: 'Private link endpoint sample workspace'
    machineLearningDescription: 'This is an example workspace having a private link endpoint.'
    location: location
    prefix: name
    tags: tags

    // dependent resources
    applicationInsightsId: applicationInsights.outputs.applicationInsightsId
    containerRegistryId: containerRegistry.outputs.containerRegistryId
    keyVaultId: keyvault.outputs.keyvaultId
    storageAccountId: storage.outputs.storageId
    storageAccountName: storage.outputs.storageAccountName
    containerName: storage.outputs.containerName
    storageKey: storage.outputs.storageAccountKey
    environmentObject: storage.outputs.environmentObject

    // // networking
    // subnetId: '${vnet.outputs.id}/subnets/snet-training'
    // computeSubnetId: '${vnet.outputs.id}/subnets/snet-training'
    // virtualNetworkId: vnet.outputs.id
    // machineLearningPleName: 'ple-${name}-${uniqueSuffix}-mlw'

    // compute
    amlComputePublicIp: amlComputePublicIp
    vmSizeParam: amlComputeDefaultVmSize
  }
}

