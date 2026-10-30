## Steps to Create Infra:
1. Create a module folder and keep the code modular.
2. Create machine learning workspace through a separate bicep template along with compute resources.
3. Create storage account, container registry and key vault using separate bicep template for each.
4. Create a common role assignment bicep file to assign minimum required access to each resource as per the orgnization policy.
5. Optionally create virtual network along with Network security groups to restrict public access along with jumpbox or dnsresolver as per organizational needs.
6. Finally create a main.bicep file and define the modules to create workspace and its dependent resources.
7. This workflow creates infra inside already existing resource group and hence - 'az deployment group create' command is used, alternatively 'az deployment sub create' can be used if creating the resource group as well within the infra code.