variable "name" {
  type = string
}

variable "service_principal" {
  default = null
  type = object({
    client_id     = string
    client_secret = string
  })
}

variable "rg" {
  type = object({
    name     = string
    location = string
  })
}

variable "vnet_id" {
  default = null
}

variable "node_resource_group" {
  default = null
}

variable "kubernetes_version" {}

variable "automatic_channel_upgrade" {
  default = "stable"
}


# Control plane api access ####################################################

variable "private_dns_zone_id" {
  default = "None"
}

variable "dns_prefix" {
  default = null
}

variable "private_cluster_enabled" {
  default = true
}

variable "private_cluster_public_fqdn_enabled" {
  default = true
}


# RBAC and authentication #####################################################

variable "role_based_access_control_enabled" {
  default = true
}

variable "local_account_disabled" {
  default = true
}

variable "aad_rbac_managed" {
  default = true
}

variable "aad_rbac_azure_rbac_enabled" {
  default = true
}

variable "aad_rbac_admin_group_object_ids" {
  default = []
}


# Network profile #############################################################

variable "network_plugin" {
  default = "kubenet"
}

variable "pod_cidr" {
  default = "172.25.0.0/16"
}

variable "service_cidr" {
  default = "172.20.0.0/16"
}

variable "dns_service_ip" {
  default = "172.20.0.10"
}

variable "network_outbound_type" {
  default = "loadBalancer"
}


# Node pools ##################################################################

variable "node_admin_username" {
  type    = string
  default = "node-admin"
}

variable "node_admin_ssh_key" {
  type = string
}

variable "node_pools" {
  type = map(object({
    default              = optional(bool, false)
    enable_auto_scaling  = optional(bool, true)
    node_count           = optional(number)
    min_count            = optional(number, 1)
    max_count            = optional(number)
    vm_size              = optional(string, "standard_b2ms")
    vnet_subnet_id       = optional(string)
    orchestrator_version = optional(string)
    class                = optional(string, "general")
    node_taints          = optional(set(string))
    linux_os_config = optional(object({
      sysctl_config = optional(object({
        vm_max_map_count = optional(number)
      }))
    }))
  }))
  default = {}
}

variable "default_node_pool_temporary_name_for_rotation" {
  default = "temp"
}

variable "default_node_pool_subnet_id" {
  default = null
}





