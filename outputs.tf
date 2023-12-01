output "this" {
  value = azurerm_kubernetes_cluster.this
}

output "identities" {
  value = { for k, v in module.identities : k => v.this }
}

output "identity_helm_release_values" {
  value = { for k, v in module.identities : k => {
    pod = { labels = { "azure.workload.identity/use" = "true" } }
    serviceaccount = {
      enabled     = true
      annotations = { "azure.workload.identity/client-id" = v.this.client_id }
    }
  } }
}