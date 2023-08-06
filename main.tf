locals {
  subnet_ids   = toset([for k, v in var.node_pools : v["vnet_subnet_id"]])
  default_pool = [for k, v in var.node_pools : k if v["default"] == true][0]
}

resource "azurerm_kubernetes_cluster" "this" {
  name                                = var.name
  location                            = var.rg.location
  resource_group_name                 = var.rg.name
  dns_prefix                          = coalesce(var.dns_prefix, substr(var.name, 0, 42))
  kubernetes_version                  = var.kubernetes_version
  node_resource_group                 = var.node_resource_group
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_dns_zone_id
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  local_account_disabled              = var.local_account_disabled
  azure_active_directory_role_based_access_control {
    managed                = var.aad_rbac_managed
    admin_group_object_ids = var.aad_rbac_admin_group_object_ids
    azure_rbac_enabled     = var.aad_rbac_azure_rbac_enabled
  }
  service_principal {
    client_id     = var.service_principal.client_id
    client_secret = var.service_principal.client_secret
  }
  network_profile {
    outbound_type  = var.network_outbound_type
    network_plugin = var.network_plugin
    pod_cidr       = var.pod_cidr
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }
  linux_profile {
    admin_username = var.node_admin_username
    ssh_key {
      key_data = var.node_admin_ssh_key
    }
  }
  default_node_pool {
    name                 = local.default_pool
    vnet_subnet_id       = coalesce(var.node_pools[local.default_pool].vnet_subnet_id, var.default_node_pool_subnet_id)
    enable_auto_scaling  = var.node_pools[local.default_pool].enable_auto_scaling
    node_count           = var.node_pools[local.default_pool].node_count
    min_count            = var.node_pools[local.default_pool].enable_auto_scaling ? var.node_pools[local.default_pool].min_count : null
    max_count            = var.node_pools[local.default_pool].enable_auto_scaling ? var.node_pools[local.default_pool].max_count : null
    vm_size              = var.node_pools[local.default_pool].vm_size
    orchestrator_version = var.node_pools[local.default_pool].orchestrator_version
    node_taints          = var.node_pools[local.default_pool].node_taints
    node_labels = {
      nodePoolName  = local.default_pool
      nodePoolClass = var.node_pools[local.default_pool].class
    }
    temporary_name_for_rotation = var.default_node_pool_temporary_name_for_rotation
    dynamic "linux_os_config" {
      for_each = var.node_pools[local.default_pool].linux_os_config == null ? {} : { 1 = var.node_pools[local.default_pool].linux_os_config }
      content {
        dynamic "sysctl_config" {
          for_each = linux_os_config.value["sysctl_config"] == null ? {} : { 1 = linux_os_config.value["sysctl_config"] }
          content {
            vm_max_map_count = sysctl_config.value["vm_max_map_count"]
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      network_profile,
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each              = { for k, v in var.node_pools : k => v if k != local.default_pool }
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.key
  vnet_subnet_id        = coalesce(each.value.vnet_subnet_id, var.default_node_pool_subnet_id)
  node_count            = each.value.node_count
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  vm_size               = each.value.vm_size
  orchestrator_version  = each.value.orchestrator_version
  node_taints           = each.value.node_taints
  node_labels = {
    nodePoolName  = each.key
    nodePoolClass = each.value.class
  }
  dynamic "linux_os_config" {
    for_each = each.value.linux_os_config == null ? {} : { 1 = each.value.linux_os_config }
    content {
      dynamic "sysctl_config" {
        for_each = linux_os_config.value["sysctl_config"] == null ? {} : { 1 = linux_os_config.value["sysctl_config"] }
        content {
          vm_max_map_count = sysctl_config.value["vm_max_map_count"]
        }
      }
    }
  }
}