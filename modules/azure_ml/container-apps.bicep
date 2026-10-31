@description('Name of the existing Azure Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the existing Service Bus queue used for SEC filing ingestion requests')
param serviceBusQueueName string

@description('Fully qualified Service Bus namespace endpoint (e.g., <namespace>.servicebus.windows.net)')
param fullyQualifiedNamespace string

@description('Name of the existing Azure Cosmos DB account')
param cosmosAccountName string

@description('Name of the Cosmos DB SQL database containing QuantiGence metadata')
param cosmosDatabaseName string

@description('Name of the Cosmos DB container storing the SEC filing registry')
param cosmosContainerName string

@description('Name of the existing Log Analytics Workspace used for Container Apps monitoring')
param logAnalyticsWorkspaceName string

@description('Name of the existing Machine Learning Workspace used for python dispatcher')
param mlWorkspaceName string

@description('Base name used to generate Container Apps Managed Environment and Job resource names')
param resourceName string = 'quantigencecont'

@description('Azure region in which Container Apps resources will be deployed')
param location string


resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosAccountName
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: '${resourceName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
      }
    }
  }

resource containerAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'container-apps-logs'
  scope: managedEnvironment
  properties: {
    workspaceId: workspace.id

    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
      }
    ]

    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource job 'Microsoft.App/jobs@2025-01-01' = {
  name: '${resourceName}-cajob'
  location: location

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    configuration: {
      triggerType: 'Event'


      eventTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1

        scale: {
          minExecutions: 0
          maxExecutions: 5
          pollingInterval: 30

          rules: [
            {
              name: 'servicebus-queue-trigger'
              type: 'azure-servicebus'

              metadata: {
                  namespace: serviceBusNamespaceName
                  queueName: serviceBusQueueName
                  messageCount: '1'
                }

              // Authenticate KEDA using the Job's SAI
              identity: 'system'
            }
          ]
        }
      }

      replicaRetryLimit: 3
      replicaTimeout: 900
    }

    environmentId: managedEnvironment.id

    template: {
      containers: [
        {
          name: 'quantigence-dispatcher'
          image: 'jackofallops/azure-containerapps-python-acctest:v0.0.1'

          resources: {
            cpu: any('0.5')
            memory: '1Gi'
          }

          env: [
            {
              name: 'AZURE_ML_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            {
              name: 'AZURE_ML_RESOURCE_GROUP'
              value: resourceGroup().name
            }
            {
              name: 'AZURE_ML_WORKSPACE'
              value: mlWorkspaceName
            }
            {
              name: 'SERVICEBUS_FULLY_QUALIFIED_NAMESPACE'
              value: fullyQualifiedNamespace
            }
            {
              name: 'SERVICEBUS_QUEUE_NAME'
              value: serviceBusQueueName
            }
            {
              name: 'COSMOS_ENDPOINT'
              value: cosmosAccount.properties.documentEndpoint
            }
            {
              name: 'COSMOS_DATABASE'
              value: cosmosDatabaseName
            }
            {
              name: 'COSMOS_CONTAINER'
              value: cosmosContainerName
            }
          ]
        }
      ]
    }
  }
}

param cosmosDataContributorRoleID string= '00000000-0000-0000-0000-000000000002'

resource cosmosDataContributorRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' existing = {
  parent: cosmosAccount
  name: cosmosDataContributorRoleID
}

resource cosmosDataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosAccount
  name: guid(
    cosmosAccount.id,
    cosmosDataContributorRole.id,
    cosmosAccount.id
  )
  properties: {
    principalId: job.identity.principalId
    roleDefinitionId: cosmosDataContributorRole.id
    scope: cosmosAccount.id
  }
}

module roleAssignments 'roleassignment.bicep' = {
  name: 'roleAssignmentContainerAppsJobs'
  params: {
    principalID: job.identity.principalId
    roleDefinitionIds: ['4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0','f6c7c914-8db3-469d-8ca1-694a8f32e121','7f951dda-4ed3-4680-a7ca-43fe172d538d']
  }
}
