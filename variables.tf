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
  default = {}
}


# Default node pool settings ##################################################

variable "default_node_pool_name" {
  default = "pool0001"
}

variable "default_node_pool_class" {
  default = "general"
}

variable "default_node_pool_node_count" {
  default = null
}

variable "default_node_pool_min_count" {
  default = 1
}

variable "default_node_pool_max_count" {
  default = null
}

variable "default_node_pool_vm_size" {
  default = "standard_b2ms"
}

variable "default_node_pool_enable_auto_scaling" {
  default = true
}

variable "default_node_pool_subnet_id" {
  default = null
}

variable "default_node_pool_node_taints" {
  default = null
}