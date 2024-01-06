locals {
  node_pools = [for k, v in var.node_pools : {
    name                 = k
    default              = try(v["default"], length(var.node_pools) == 1 ? true : false)
    enable_auto_scaling  = try(v["enable_auto_scaling"], var.default_node_pool_enable_auto_scaling)
    node_count           = try(v["node_count"], var.default_node_pool_node_count)
    min_count            = try(v["min_count"], var.default_node_pool_min_count)
    max_count            = try(v["max_count"], var.default_node_pool_max_count)
    vm_size              = try(v["vm_size"], var.default_node_pool_vm_size)
    vnet_subnet_id       = try(v["subnet_id"], var.default_node_pool_subnet_id)
    orchestrator_version = try(v["orchestrator_version"], var.kubernetes_version)
    class                = try(v["class"], var.default_node_pool_class)
    linux_os_config      = try(v["linux_os_config"], [])
    node_taints          = try(v["node_taints"], var.default_node_pool_node_taints)
  }]
  subnet_ids         = distinct([for pool in local.node_pools : pool["vnet_subnet_id"]])
  default_pool_index = index(local.node_pools.*.default, true)
}

resource "azurerm_kubernetes_cluster" "this" {
  name                                = var.name
  location                            = var.rg.location
  resource_group_name                 = var.rg.name
  dns_prefix                          = var.name
  kubernetes_version                  = var.kubernetes_version
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    managed                = var.aad_role_based_access_control_managed
    admin_group_object_ids = var.aad_role_based_access_control_admin_group_object_ids
  }
  service_principal {
    client_id     = var.service_principal.client_id
    client_secret = var.service_principal.client_secret
  }
  network_profile {
    outbound_type      = var.network_outbound_type
    network_plugin     = var.network_plugin
    pod_cidr           = var.pod_cidr
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
  }
  linux_profile {
    admin_username = var.node_admin_username
    ssh_key {
      key_data = var.node_admin_ssh_key
    }
  }
  default_node_pool {
    name                 = local.node_pools[local.default_pool_index]["name"]
    enable_auto_scaling  = local.node_pools[local.default_pool_index]["enable_auto_scaling"]
    node_count           = local.node_pools[local.default_pool_index]["node_count"]
    min_count            = local.node_pools[local.default_pool_index]["enable_auto_scaling"] ? local.node_pools[local.default_pool_index]["min_count"] : null
    max_count            = local.node_pools[local.default_pool_index]["enable_auto_scaling"] ? local.node_pools[local.default_pool_index]["max_count"] : null
    vm_size              = local.node_pools[local.default_pool_index]["vm_size"]
    vnet_subnet_id       = local.node_pools[local.default_pool_index]["vnet_subnet_id"]
    orchestrator_version = local.node_pools[local.default_pool_index]["orchestrator_version"]
    node_taints          = local.node_pools[local.default_pool_index]["node_taints"]
    node_labels = {
      nodePoolName  = local.node_pools[local.default_pool_index]["name"]
      nodePoolClass = local.node_pools[local.default_pool_index]["class"]
    }
    dynamic "linux_os_config" {
      for_each = local.node_pools[local.default_pool_index]["linux_os_config"]
      content {
        dynamic "sysctl_config" {
          for_each = try(linux_os_config.value["sysctl_config"], {})
          content {
            vm_max_map_count = try(sysctl_config.value.vm_max_map_count, null)
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
  for_each              = { for i, v in local.node_pools : v["name"] => v if i != local.default_pool_index }
  name                  = each.value["name"]
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vnet_subnet_id        = each.value["vnet_subnet_id"]
  node_count            = each.value["node_count"]
  enable_auto_scaling   = each.value["enable_auto_scaling"]
  min_count             = each.value["enable_auto_scaling"] ? each.value["min_count"] : null
  max_count             = each.value["enable_auto_scaling"] ? each.value["max_count"] : null
  vm_size               = each.value["vm_size"]
  orchestrator_version  = each.value["orchestrator_version"]
  node_taints           = each.value["node_taints"]
  node_labels = {
    nodePoolName  = each.value["name"]
    nodePoolClass = each.value["class"]
  }
  dynamic "linux_os_config" {
    for_each = each.value["linux_os_config"]
    content {
      dynamic "sysctl_config" {
        for_each = try(linux_os_config.value["sysctl_config"], [])
        content {
          vm_max_map_count = try(sysctl_config.value.vm_max_map_count, null)
        }
      }
    }
  }
}