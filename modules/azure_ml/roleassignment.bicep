@description('Principal ID of the Resource, generally System Assigned Managed Identity')
param principalID string

@description('List of role Definition IDs for the resource')
param roleDefinitionIds array

// Compute cluster role assignments
resource roleAssignmentMLCompCluster 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleId in roleDefinitionIds: {
    name: guid(
      principalID,
      roleId,
      resourceGroup().id
    )
    properties: {
      principalId: principalID
      principalType: 'ServicePrincipal'
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        roleId
      )
    }
  }
]
