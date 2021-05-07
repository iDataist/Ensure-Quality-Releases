uniqueid=20210508
resourcegroup="group$uniqueid"
location='westus2'
storageaccount="tfbackend$uniqueid" 
container="tf-backend-files-$uniqueid"
keyvault="secrets-kv-$uniqueid"
sp="sp-$uniqueid"

# Create the resource group
az group create \
-n $resourcegroup \
-l $location

# Create the key vault
az keyvault create \
-n $keyvault \
-g $resourcegroup \
-l $location

# Create storage account
az storage account create \
--resource-group $resourcegroup \
--name $storageaccount \
--sku Standard_LRS \
--encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $resourcegroup --account-name $storageaccount --query [0].value -o tsv)

# Create container
az storage container create \
--name $container \
--account-name $storageaccount \
--account-key $ACCOUNT_KEY

# Add the storage account key as a secret in the key vault
az keyvault secret set \
--vault-name $keyvault \
--name "tf-backend-sa-access-key" \
--value "$ACCOUNT_KEY"

# Create terraform service principal
SP=$(az ad sp create-for-rbac)
# Client ID of the service principal
CLIENT_ID=$(echo $SP | jq '.appId' | sed 's/"//g')
# Client secret of the service principal
CLIENT_SECRET=$(echo $SP | jq '.password' | sed 's/"//g')
echo $CLIENT_SECRET
# Set your tenant ID
TENANT_ID=$(echo $SP | jq '.tenant' | sed 's/"//g')
# Set your subscription ID
SUBSCRIPTION=$(az account show --query id --output tsv)
# Set your subscription ID
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)

# Add the values as secrets to key vault
az keyvault secret set --vault-name $keyvault --name "sp-id" --value "$CLIENT_ID"
az keyvault secret set --vault-name $keyvault --name "sp-secret" --value "$CLIENT_SECRET"
az keyvault secret set --vault-name $keyvault --name "tenant-id" --value "$TENANT_ID"
az keyvault secret set --vault-name $keyvault --name "subscription-id" --value "$SUBSCRIPTION"

# Give the SP access to get pipeline secrets
az role assignment create \
--assignee $CLIENT_ID \
--scope "/subscriptions/${SUBSCRIPTION}/resourceGroups/${resourcegroup}/providers/Microsoft.KeyVault/vaults/${keyvault}" \
--role "reader"

az keyvault set-policy \
--name $keyvault \
--spn $CLIENT_ID \
--subscription $SUBSCRIPTION \
--secret-permissions get

# Create an DevOps service connection using the above service principal
az devops service-endpoint azurerm create \
--azure-rm-service-principal-id $CLIENT_ID \
--azure-rm-subscription-id $SUBSCRIPTION \
--azure-rm-subscription-name $SUBSCRIPTION_NAME \
--azure-rm-tenant-id $TENANT_ID \
--name $sp \
--organization "https://dev.azure.com/hwdgrmy/" \
--project "Ensuring Quality Releases"

# Set the VM username and password and save them to keyvault
az keyvault secret set --vault-name $keyvault --name "vm-user" --value "vmadmin$uniqueid"
az keyvault secret set --vault-name $keyvault --name "vm-password" --value "p@ssword$uniqueid"

# Set up log analytics workspace
az deployment group create \
--resource-group $resourcegroup \
--name deploy-group \
--template-file deploymentTemplate.json

# # Install Log Analytics agent on the VM
# ssh [ADMIN]@[PUBLIC-IP]
# sudo adduser [USERNAME] sudo
# wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <YOUR WORKSPACE ID> -s <YOUR WORKSPACE PRIMARY KEY>


