terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "network" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  vnets = {
    vnet1 = { address_space = var.vnet1_address_space, asn = 65010, prefix = "10.1" }
    vnet2 = { address_space = var.vnet2_address_space, asn = 65020, prefix = "10.2" }
    vnet3 = { address_space = var.vnet3_address_space, asn = 65030, prefix = "10.3" }
  }
  workload_subnets = {
    subnet1 = 1
    subnet2 = 2
    subnet3 = 3
    subnet4 = 4
  }
  vnet_keys = ["vnet1", "vnet2", "vnet3"]
  vpn_links = {
    vnet1_to_vnet2 = { left = "vnet1", right = "vnet2" }
    vnet2_to_vnet1 = { left = "vnet2", right = "vnet1" }
    vnet2_to_vnet3 = { left = "vnet2", right = "vnet3" }
    vnet3_to_vnet2 = { left = "vnet3", right = "vnet2" }
  }
  vm_vnets = { vm1 = "vnet1", vm2 = "vnet2", vm3 = "vnet3" }
}

resource "azurerm_virtual_network" "this" {
  for_each            = local.vnets
  name                = each.key
  address_space       = [each.value.address_space]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  for_each             = local.vnets
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this[each.key].name
  address_prefixes     = [cidrsubnet(each.value.address_space, 11, 2047)]
}

resource "azurerm_subnet" "workload" {
  for_each             = { for pair in setproduct(keys(local.vnets), keys(local.workload_subnets)) : "${pair[0]}_${pair[1]}" => { vnet = pair[0], subnet = pair[1], index = local.workload_subnets[pair[1]] } }
  name                 = each.value.subnet
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this[each.value.vnet].name
  address_prefixes     = ["${local.vnets[each.value.vnet].prefix}.${each.value.index}.0/24"]
}

resource "azurerm_network_security_group" "workload" {
  for_each            = local.vnets
  name                = "${each.key}-workload-nsg"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  for_each                  = azurerm_subnet.workload
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.workload[split("_", each.key)[0]].id
}

resource "azurerm_public_ip" "gateway" {
  for_each            = local.vnets
  name                = "${each.key}-vpn-gateway-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.gateway_zones
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  for_each            = local.vnets
  name                = "${each.key}-vpn-gateway"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  generation          = var.vpn_gateway_generation
  active_active       = false
  enable_bgp          = true
  tags                = var.tags

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gateway[each.key].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[each.key].id
  }

  bgp_settings {
    asn = each.value.asn
  }
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each                   = local.vpn_links
  name                       = each.key
  location                   = azurerm_resource_group.network.location
  resource_group_name        = azurerm_resource_group.network.name
  type                       = "Vnet2Vnet"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this[each.value.left].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.this[each.value.right].id
  shared_key                 = var.vpn_shared_key
  enable_bgp                 = true
  tags                       = var.tags
}

resource "azurerm_network_interface" "vm" {
  for_each            = local.vm_vnets
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload["${each.value}_subnet1"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = local.vm_vnets
  name                            = each.key
  computer_name                   = each.key
  location                        = azurerm_resource_group.network.location
  resource_group_name             = azurerm_resource_group.network.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm[each.key].id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_monitor_action_group" "operations" {
  name                = "network-alerts"
  resource_group_name = azurerm_resource_group.network.name
  short_name          = "netalerts"
  tags                = var.tags

  email_receiver {
    name          = "operations"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "vm_cpu" {
  for_each            = azurerm_linux_virtual_machine.vm
  name                = "${each.key}-high-cpu"
  resource_group_name = azurerm_resource_group.network.name
  scopes              = [each.value.id]
  description         = "Average VM CPU percentage is above the configured threshold."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }
  action { action_group_id = azurerm_monitor_action_group.operations.id }
}

resource "azurerm_monitor_metric_alert" "vpn_tunnel_ingress" {
  for_each            = azurerm_virtual_network_gateway.this
  name                = "${each.key}-vpn-tunnel-ingress"
  resource_group_name = azurerm_resource_group.network.name
  scopes              = [each.value.id]
  description         = "VPN gateway tunnel ingress traffic is below the configured threshold."
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "TunnelIngressBytes"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = var.vpn_ingress_alert_threshold
  }
  action { action_group_id = azurerm_monitor_action_group.operations.id }
}
