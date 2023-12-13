output "this" {
  value = azurerm_kubernetes_cluster.this
}

output "kube_config" {
  value = coalesce(one(azurerm_kubernetes_cluster.this.kube_admin_config[*]), one(azurerm_kubernetes_cluster.this.kube_config[*]))
}

output "kube_config_raw" {
  sensitive = true
  value = coalesce(one(azurerm_kubernetes_cluster.this.kube_admin_config_raw[*]), one(azurerm_kubernetes_cluster.this.kube_config_raw[*]))
}

output "identities" {
  value = { for k, v in module.identities : k => v.this }
}

output "identity_helm_release_values" {
  value = { for k, v in module.identities : k => {
    pod = { labels = { "azure.workload.identity/use" = "true" } }
    serviceAccount = {
      annotations = { "azure.workload.identity/client-id" = v.this["client_id"] }
    }
  } }
}