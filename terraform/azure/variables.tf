variable "subscription_id" {
  description = "Azure subscription ID. Can also be provided through ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the resource group for the lab topology."
  type        = string
  default     = "rg-hybrid-vpn-lab"
}

variable "location" {
  description = "Azure region in which to deploy all resources."
  type        = string
  default     = "westeurope"
}

variable "vnet1_address_space" {
  description = "Address range for vnet1."
  type        = string
  default     = "10.1.0.0/16"
}

variable "vnet2_address_space" {
  description = "Address range for vnet2."
  type        = string
  default     = "10.2.0.0/16"
}

variable "vnet3_address_space" {
  description = "Address range for vnet3."
  type        = string
  default     = "10.3.0.0/16"
}

variable "vpn_gateway_sku" {
  description = "SKU for each VPN gateway. Confirm BGP support and regional availability before deployment."
  type        = string
  default     = "VpnGw1"
}

variable "vpn_gateway_generation" {
  description = "VPN gateway generation."
  type        = string
  default     = "Generation1"
}

variable "gateway_zones" {
  description = "Availability zones for gateway public IPs; leave empty in regions or SKUs that do not support zonal gateways."
  type        = list(string)
  default     = []
}

variable "vpn_shared_key" {
  description = "Shared IPsec key used on both VNet-to-VNet links. Supply securely via TF_VAR_vpn_shared_key or a secret manager."
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Linux VM administrator username."
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key installed on all three Linux VMs."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size for vm1, vm2, and vm3."
  type        = string
  default     = "Standard_B2s"
}

variable "alert_email" {
  description = "Email address notified by the VM and VPN gateway alerts."
  type        = string
}

variable "cpu_alert_threshold" {
  description = "Average CPU percentage above which a VM alert fires."
  type        = number
  default     = 80
}

variable "vpn_ingress_alert_threshold" {
  description = "VPN tunnel ingress bytes below which a gateway alert fires. Configure based on expected traffic."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
  default     = { managed_by = "terraform", environment = "lab" }
}
