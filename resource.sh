uniqueId=20210503
resourceGroupName="group$uniqueId"
location='westus2'
storageAccountName="blob$uniqueId" 
containerName='container$uniqueId'

# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location

az storage account create \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --location $location

# Create a storage container
az storage container create \
    --account-name $storageAccountName \
    --name $containerName 