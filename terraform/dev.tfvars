# Resource Group/Location
location = "westus2"
resource_group = "group20210504"
application_type = "webapp20210504"

# Network
address_space = ["10.5.0.0/16"]
address_prefix_test = "10.5.1.0/24"
subnet_id = module.network.subnet_id
public_ip_address_id = module.publicip.public_ip_address_id