##############################################################################
# VPC Variables
##############################################################################

variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
}

variable "resource_group_name" {
  description = "ID for IBM Cloud Resource Group"
  default = "Default"
}

# variable "az_list" {
#   description = "IBM Cloud availability zones"
# }

variable "generation" {
  description = "VPC generation"
  default     = 2
}

# unique vpc name
variable "unique_id" {
  description = "The vpc unique id"
}


variable "frontend_count" {
  description = "number of front end zones"
  default     = 1
}

variable "backend_count" {
  description = "number of back end zones"
  default     = 1
}

##############################################################################
# Network variables
##############################################################################

variable "frontend_cidr_blocks" {
  description = "Complete CIDR range across all three zones for frontend subnets"
  default     = "172.16.0.0/20"
}

variable "backend_cidr_blocks" {
  description = "Complete CIDR range across all three zones for backend subnets"
  default     = "172.17.0.0/20"  
}
##############################################################################



