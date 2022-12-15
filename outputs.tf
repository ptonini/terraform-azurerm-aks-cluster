output "this" {
  value = azurerm_kubernetes_cluster.this
}

output "credentials" {
  value = {
    host                   = "https://${azurerm_kubernetes_cluster.this.fqdn}:443"
    username               = azurerm_kubernetes_cluster.this.kube_admin_config.0.username
    password               = azurerm_kubernetes_cluster.this.kube_admin_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.cluster_ca_certificate)
  }
}