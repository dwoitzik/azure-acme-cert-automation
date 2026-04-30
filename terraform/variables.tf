## ===========================================================
## ACME Bot - Public Edition Variables
## ===========================================================

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the Acmebot will be deployed."
  default     = "rg-acmebot-test"
}

variable "location" {
  type        = string
  description = "The Azure region to deploy the resources (e.g., 'westeurope', 'eastus')."
  default     = "westeurope"
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., dev, test, prod)."
  default     = "prod"
}

variable "acme_contact_email" {
  type        = string
  description = "The email address registered with Let's Encrypt for expiry notifications."
}

variable "dns_zone_id" {
  type        = string
  description = "The full Azure Resource ID of the public DNS Zone where the ACME TXT records will be created."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resources."
  default     = {
    ManagedBy = "Terraform"
    Project   = "Acmebot-Automation"
  }
}