locals {
  subnet_ids   = toset(compact(concat([for k, v in var.node_pools : v.vnet_subnet_id], [var.default_node_pool_subnet_id])))
  default_pool = one([for k, v in var.node_pools : k if v["default"] == true])
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
  oidc_issuer_enabled                 = var.oidc_issuer_enabled
  workload_identity_enabled           = var.workload_identity_enabled
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  local_account_disabled              = var.local_account_disabled

  azure_active_directory_role_based_access_control {
    managed                = var.aad_rbac.managed
    admin_group_object_ids = var.aad_rbac.admin_group_object_ids
    azure_rbac_enabled     = var.aad_rbac.azure_rbac_enabled
  }

  network_profile {
    outbound_type  = var.network_profile.outbound_type
    network_plugin = var.network_profile.network_plugin
    pod_cidr       = var.network_profile.pod_cidr
    service_cidr   = var.network_profile.service_cidr
    dns_service_ip = var.network_profile.dns_service_ip
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
    temporary_name_for_rotation = var.node_pools[local.default_pool].temporary_name_for_rotation

    dynamic "linux_os_config" {
      for_each = var.node_pools[local.default_pool].linux_os_config[*]
      content {

        dynamic "sysctl_config" {
          for_each = linux_os_config.value.sysctl_config[*]
          content {
            vm_max_map_count = sysctl_config.value.vm_max_map_count
          }
        }
      }
    }
  }

  dynamic "service_principal" {
    for_each = var.service_principal[*]
    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }

  dynamic "identity" {
    for_each = var.service_principal == null ? [0] : []
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider[*]
    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }

  dynamic "workload_autoscaler_profile" {
    for_each = var.keda_enabled ? [0] : []
    content {
      keda_enabled = var.keda_enabled
    }
  }

  dynamic "linux_profile" {
    for_each = var.linux_profile[*]
    content {
      admin_username = linux_profile.value.admin_username
      ssh_key {
        key_data = linux_profile.value.ssh_key_data
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_profile,
      tags["business_unit"],
      tags["environment"],
      tags["product"],
      tags["subscription_type"],
      tags["environment_finops"]
    ]
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = length(azurerm_kubernetes_cluster.this.identity) == 1 ? local.subnet_ids : []
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
  scope                = each.value
  role_definition_name = "Contributor"
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
    for_each = each.value.linux_os_config[*]
    content {

      dynamic "sysctl_config" {
        for_each = linux_os_config.value.sysctl_config[*]
        content {
          vm_max_map_count = sysctl_config.value.vm_max_map_count
        }
      }
    }
  }
}

module "identities" {
  source   = "ptonini/federated-managed-identity/azurerm"
  version  = "1.0.0"
  for_each = var.identities
  name     = "${azurerm_kubernetes_cluster.this.name}-${each.key}"
  rg       = var.rg
  scopes   = each.value.scopes
  issuer   = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject  = "system:serviceaccount:${each.value.namespace}:${each.key}"
}

