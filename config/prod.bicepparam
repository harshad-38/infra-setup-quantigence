using '../main.bicep'

param amlComputeDefaultVmSize = 'Standard_D2s_v3'
param amlComputePublicIp = true
// param azureBastionSubnetPrefix = '192.168.250.0/27'
// param deployJumphost = true
// param dsvmJumpboxPassword = 'alphaCoder@1234'
// param dsvmJumpboxUsername =  'harshad-38'
param prefix = 'mlops'
// param scoringSubnetPrefix = '192.168.1.0/24'
param tags = {
  environment: 'production'
  project: 'mlops'
}
// param trainingSubnetPrefix = '192.168.0.0/24'
// param vnetAddressPrefix = '192.168.0.0/16'
