// @description('Principal Id to which the role has to be assigned')
// param principalIDML string

// @description('Role defintion ID which consists of priviledges to be granted to ML Workspace')
// param roleDefinitionIDML string = 'b78c5d69-af96-48a3-bf8d-a8b4d589de94'

@description('Role defintion ID which consists of priviledges to be granted to ML compute cluster')
param roleDefinitionIDMLCompInstance array = ['acdd72a7-3385-48ef-bd42-f606fba81ae7', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe','7f951dda-4ed3-4680-a7ca-43fe172d538d','4633458b-17de-408a-b874-0445c86b69e6']

@description('Role defintion ID which consists of priviledges to be granted to ML compute instance')
param roleDefinitionIDCompCluster array = ['acdd72a7-3385-48ef-bd42-f606fba81ae7', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe','7f951dda-4ed3-4680-a7ca-43fe172d538d','4633458b-17de-408a-b874-0445c86b69e6']

@description('Principal ID of the computer instance attached to Machine Learning Workspace')
param principalIDComInstance string

@description('Principal ID of the compute cluster attched to Machine Learning workspace')
param principalIDMLCompCluster string

// @description('Unique Name that will be assigned to the Role Assignment')
// var roleAssignmentNameML = guid(principalIDML, roleDefinitionIDML, resourceGroup().id)

// @description('Unique Name that will be assigned to the Role Assignment')
// var roleAssignmentNameMLCompInstance = guid(principalIDComInstance, roleDefinitionIDMLCompInstance, resourceGroup().id)

// @description('Unique Name that will be assigned to the Role Assignment')
// var roleAssignmentNameMLCompCluster = guid(principalIDMLCompCluster, roleDefinitionIDCompCluster, resourceGroup().id)

// @description('Role Definition name which allows custom permissions to the system Assigned Workspace Identity')
// var roleDefinitionName = guid(resourceGroup().id)

// This is not needed because the role assignment automatically happens for the machine learning workspace
// resource roleAssignmentML 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: roleAssignmentNameML
//   properties:{
//     principalId: principalIDML
//     principalType: 'ServicePrincipal'
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIDML)
//   }
// }

resource roleAssignmentMLCompCluster 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleDefinitionID, index) in roleDefinitionIDCompCluster:{
  name: guid(principalIDMLCompCluster, roleDefinitionID, resourceGroup().id)
  properties:{
    principalId: principalIDMLCompCluster
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
  }
}]

resource roleAssignmentMLCompInstance 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleDefinitionID, index) in roleDefinitionIDMLCompInstance: {
  name: guid(principalIDComInstance, roleDefinitionID, resourceGroup().id)
  properties:{
    principalId: principalIDComInstance
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
  }
}]
// resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
//   name: roleDefinitionName
//   properties: {
//     roleName: roleDefinitionName
//     description: 'Used for end to end ML operations from this workspace'
//     type: 'CustomRole'
//     assignableScopes: [
//       resourceGroup().id
//     ]
//     permissions: [
//       {
//         actions: [
//           'Microsoft.Storage/storageAccounts/blobServices/containers/*'
//           'Microsoft.ContainerInstance/containerGroups/*'
//           'Microsoft.ContainerRegistry/register/action'
//           'Microsoft.ContainerRegistry/unregister/action'
//           'Microsoft.ContainerRegistry/registries/*'
//           'Microsoft.ContainerRegistry/registries/*/*'
//           'Microsoft.Storage/storageAccounts/*/*'

//         ]
//       }
//     ]
//   }
// }

// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: roleAssignmentName
//   properties: {
//     roleDefinitionId: roleDefinition.id
//     principalId: principalID
//     principalType: 'ServicePrincipal'
//   }
// }
