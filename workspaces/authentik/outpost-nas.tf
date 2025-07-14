resource "authentik_service_connection_kubernetes" "nas" {
  name = "nas-cluster-integration"
  kubeconfig = jsonencode({
    apiVersion = "v1"
    kind       = "Config"
    users = [{
      name = "authentik-user"
      user = {
        # kubectl -n authentik get secret/authentik-outpost-authentik-remote-cluster -o jsonpath='{.data.token}' | base64 --decode
        token = data.bitwarden_secret.authentik_nas_apiservertoken.value
      }
    }]
    clusters = [{
      name = "default-cluster"
      cluster = {
        server = "https://kubernetes-api.nas.${data.bitwarden_secret.dns_zone.value}"
    } }]
    contexts = [{
      name = "default-context"
      context = {
        user      = "authentik-user"
        cluster   = "default-cluster"
        namespace = "authentik"
      }
    }]
    current-context = "default-context"
  })
  local      = false
  verify_ssl = true
}

resource "authentik_outpost" "nas" {
  name               = "nas-cluster-outpost"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.nas.id

  config = jsonencode({
    authentik_host                   = "https://auth.homelab.${data.bitwarden_secret.dns_zone.value}"
    authentik_host_insecure          = false
    authentik_host_browser           = ""
    container_image                  = null
    docker_network                   = null
    docker_map_ports                 = true
    docker_labels                    = null
    kubernetes_disabled_components   = ["ingress", "traefik middleware"]
    kubernetes_httproute_annotations = {}
    kubernetes_httproute_parent_refs = []
    kubernetes_image_pull_secrets    = []
    kubernetes_ingress_annotations   = {},
    kubernetes_ingress_class_name    = null
    kubernetes_ingress_secret_name   = "authentik-outpost-tls"
    kubernetes_json_patches          = null
    kubernetes_namespace             = "authentik"
    kubernetes_replicas              = 1
    kubernetes_service_type          = "ClusterIP"
    log_level                        = "debug"
    object_naming_template           = "ak-outpost-%(name)s"
    refresh_interval                 = "minutes=5"
  })
  protocol_providers = [
    module.proxy_traefik_nas.proxy_provider.id
  ]
}
