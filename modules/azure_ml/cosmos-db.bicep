
@description('Tags to add to the resources')
param tags object

@description('Resource name provided to the Cosmos DB account')
param resourceName string

@description('Location in which the Cosmos DB account will be created')
param location string = 'eastus2'

@description('Name of the Cosmos DB SQL database')
param databaseName string = 'quantigence'

@description('Name of the filing registry container')
param containerName string = 'filing-registry'


resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: resourceName
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    capabilities: []

    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }

    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 48
        backupStorageRedundancy: 'Local'
      }
    }

    databaseAccountOfferType: 'Standard'
    disableKeyBasedMetadataWriteAccess: false
    disableLocalAuth: true
    enableFreeTier: true

    locations: [
        {
          failoverPriority: 0
          isZoneRedundant: false
          locationName: 'East US 2'
        }
    ]

    networkAclBypass: 'None'
    publicNetworkAccess: 'Enabled'
  }
}


// SQL Database
resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-10-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 400
    }
  }
}


// Filing Registry Container
resource filingRegistry 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: sqlDatabase
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        kind: 'Hash'
        version: 2
        paths: [
          '/cik'
        ]
      }
    }
    options: {}
  }
}


// Outputs for Container Apps and other modules
output cosmosAccountId string = cosmosAccount.id
output cosmosAccountName string = cosmosAccount.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint

output databaseId string = sqlDatabase.id
output databaseName string = sqlDatabase.name

output containerId string = filingRegistry.id
output containerName string = filingRegistry.name
