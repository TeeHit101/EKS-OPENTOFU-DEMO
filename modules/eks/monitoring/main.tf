locals {
  tolerations = length(var.system_node_group_names) > 0 ? [
    {
      key      = "CriticalAddonsOnly"
      operator = "Exists"
    }
  ] : []

  affinity = length(var.system_node_group_names) > 0 ? {
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            matchExpressions = [
              {
                key      = "node_group"
                operator = "In"
                values   = var.system_node_group_names
              }
            ]
          }
        ]
      }
    }
  } : {}
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = var.namespace
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }

  type = "Opaque"

  depends_on = [helm_release.prometheus_stack] # Ensure namespace exists if created by helm
}

resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = false

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "10d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes      = ["ReadWriteOnce"]
                storageClassName = "gp3"
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
          affinity    = local.affinity
          tolerations = local.tolerations
        }
      }
      grafana = {
        admin = {
          existingSecret = "grafana-admin-credentials"
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }
        affinity    = local.affinity
        tolerations = local.tolerations
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          affinity    = local.affinity
          tolerations = local.tolerations
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes      = ["ReadWriteOnce"]
                storageClassName = "gp3"
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
      kubeStateMetrics = {
        affinity    = local.affinity
        tolerations = local.tolerations
      }
      nodeExporter = {
        tolerations = [
          {
            operator = "Exists"
          }
        ]
      }
    })
  ]
}
