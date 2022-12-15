variable "name" {}

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

variable "kubernetes_version" {}

variable "automatic_channel_upgrade" {
  default = "stable"
}

variable "private_cluster_enabled" {
  default = true
}

variable "private_cluster_public_fqdn_enabled" {
  default = true
}

variable "api_server_authorized_ip_ranges" {
  default = null
}

variable "role_based_access_control_enabled" {
  default = true
  type    = bool
}

variable "aad_role_based_access_control_managed" {
  default = true
}

variable "aad_role_based_access_control_admin_group_object_ids" {
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
  default = "172.16.0.0/16"
}

variable "dns_service_ip" {
  default = "172.16.0.10"
}

variable "docker_bridge_cidr" {
  default = "172.17.0.1/16"
}

variable "network_outbound_type" {
  default = "loadBalancer"
}


# Nodes #######################################################################

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


# Default node pool ###########################################################

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
  default = "standard_ds2_v2"
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

variable "default_node_scale_down_mode" {
  default = "Deallocate"
}