
@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the queue')
param serviceBusQueueName string

@description('Location for all resources')
param location string

@description('Default message lifetime')
param messageTimeToLive string = 'P7D'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    disableLocalAuth: true
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2024-01-01' = {
  parent: serviceBusNamespace
  name: serviceBusQueueName
  properties: {
    // Message processing
    lockDuration: 'PT5M'
    maxDeliveryCount: 10
    defaultMessageTimeToLive: messageTimeToLive

    // Duplicate protection
    requiresDuplicateDetection: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'

    // Failure handling
    deadLetteringOnMessageExpiration: true

    // Queue configuration
    maxSizeInMegabytes: 1024
    requiresSession: false
    enablePartitioning: false
    enableExpress: false
    enableBatchedOperations: true
  }
}

output namespaceId string = serviceBusNamespace.id
output serviceBusNamespaceName string = serviceBusNamespace.name
output queueId string = serviceBusQueue.id
output serviceBusQueueName string = serviceBusQueue.name

output fullyQualifiedNamespace string = '${serviceBusNamespace.name}.servicebus.windows.net'
