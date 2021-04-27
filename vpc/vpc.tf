##############################################################################
# This file creates the VPC, Zones, subnets, acls and public gateway for the 
# example VPC. It is not intended to be a full working application 
# environment. 
#
# Separately setup up any required load balancers, listeners, pools and members
##############################################################################

# provider block required with Schematics to set VPC region
provider "ibm" {
  region = var.ibm_region
  #ibmcloud_api_key = var.ibmcloud_api_key
  generation = local.generation
  version    = "~> 1.4"
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

locals {
  generation     = 2
  frontend_count = 2
  backend_count  = 1
}


##################################################################################################
#  Select CIDRs allowed to access bastion host  
#  When running under Schematics allowed ingress CIDRs are set to only allow access from Schematics  
#  for use with Remote-exec and Redhat Ansible
#  When running under Terraform local execution ingress is set to 0.0.0.0/0
#  Access CIDRs are overridden if user_bastion_ingress_cidr is set to anything other than "0.0.0.0/0" 
##################################################################################################


data "external" "env" { program = ["jq", "-n", "env"] }
locals {
  region = lookup(data.external.env.result, "TF_VAR_SCHEMATICSLOCATION", "")
  geo    = substr(local.region, 0, 2)
  schematics_ssh_access_map = {
    us = ["169.44.0.0/14", "169.60.0.0/14"],
    eu = ["158.175.0.0/16","158.176.0.0/15","141.125.75.80/28","161.156.139.192/28","149.81.103.128/28"],
  }
  schematics_ssh_access = lookup(local.schematics_ssh_access_map, local.geo, ["0.0.0.0/0"])
  bastion_ingress_cidr  = var.ssh_source_cidr_override[0] != "0.0.0.0/0" ? var.ssh_source_cidr_override : local.schematics_ssh_access
}

##############################################################################
# Create a VPC
##############################################################################
data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name                      = var.unique_id
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

##############################################################################






##############################################################################
# Prefixes and subnets for zone 1
##############################################################################



resource "ibm_is_vpc_address_prefix" "frontend_subnet_prefix" {
  count = var.frontend_count
  name  = "${var.unique_id}-frontend-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.frontend_cidr_blocks[count.index]

}

resource "ibm_is_vpc_address_prefix" "backend_subnet_prefix" {
  count = var.backend_count
  name  = "${var.unique_id}-backend-prefix-zone-${count.index + 1}"
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"
  vpc   = ibm_is_vpc.vpc.id
  cidr  = var.backend_cidr_blocks[count.index]
}

##############################################################################

##############################################################################
# Create Subnets
##############################################################################




# Increase count to create subnets in all zones
resource "ibm_is_subnet" "frontend_subnet" {
  count           = var.frontend_count
  name            = "${var.unique_id}-frontend-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.frontend_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.frontend_subnet_prefix]
}

# Increase count to create subnets in all zones
resource "ibm_is_subnet" "backend_subnet" {
  count           = var.backend_count
  name            = "${var.unique_id}-backend-subnet-${count.index + 1}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "${var.ibm_region}-${count.index % 3 + 1}"
  ipv4_cidr_block = var.backend_cidr_blocks[count.index]
  #network_acl     = "${ibm_is_network_acl.multizone_acl.id}"
  #public_gateway = ibm_is_public_gateway.repo_gateway[count.index].id
  depends_on     = [ibm_is_vpc_address_prefix.backend_subnet_prefix]
}





# Increase count to create gateways in all zones
resource "ibm_is_public_gateway" "repo_gateway" {
  count = var.frontend_count
  name  = "${var.unique_id}-public-gtw-${count.index}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.ibm_region}-${count.index % 3 + 1}"

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}





#############################################################################




