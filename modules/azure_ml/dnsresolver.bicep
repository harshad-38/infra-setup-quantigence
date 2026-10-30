@description('name of the dns resolver')
param dnsResolverName string = 'dns-resolver-p2s'

@description('name of the subnet that will be used for private resolver inbound endpoint')
param inboundSubnet string = 'snet-dns-inbound'

@description('location of the dns resolver')
param location string = resourceGroup().location

@description('Tags to apply to the  DNS Resolver')
param tags object = {}

resource resolverVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-mlops'
  scope: resourceGroup()
}

// Explicitly reference the existing subnet
resource inboundSubnetRef 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: resolverVnet
  name: inboundSubnet
}

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsResolverName
  location: location
  tags: tags
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: resolver
  name: inboundSubnet
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAddress: '192.168.3.4'
        privateIpAllocationMethod: 'Static'
        subnet: {
          id: inboundSubnetRef.id
        }
      }
    ]
  }
}

