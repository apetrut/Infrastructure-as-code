output "resource_group_name" {
  description = "Resource group containing the topology."
  value       = azurerm_resource_group.network.name
}

output "vnet_address_spaces" {
  description = "Address space for each virtual network."
  value       = { for name, vnet in azurerm_virtual_network.this : name => vnet.address_space }
}

output "vpn_gateway_public_ips" {
  description = "Public IP address of each VPN gateway."
  value       = { for name, ip in azurerm_public_ip.gateway : name => ip.ip_address }
}

output "vm_private_ips" {
  description = "Private IP address of each VM."
  value       = { for name, nic in azurerm_network_interface.vm : name => nic.private_ip_address }
}

output "bgp_asns" {
  description = "BGP ASN assigned to each VPN gateway."
  value       = { for name, config in local.vnets : name => config.asn }
}
