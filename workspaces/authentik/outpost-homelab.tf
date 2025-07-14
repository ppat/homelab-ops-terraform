resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes Cluster"
  local = true
}

resource "authentik_outpost" "embedded_outpost" {
  name               = "authentik Embedded Outpost"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.local.id

  config = jsonencode({
    authentik_host                 = "https://auth.homelab.${data.bitwarden_secret.dns_zone.value}"
    authentik_host_insecure        = false
    authentik_host_browser         = ""
    container_image                = null
    docker_network                 = null
    docker_map_ports               = true
    docker_labels                  = null
    kubernetes_disabled_components = []
    kubernetes_image_pull_secrets  = []
    kubernetes_ingress_annotations = {},
    kubernetes_ingress_class_name  = null
    kubernetes_ingress_secret_name = "authentik-outpost-tls"
    kubernetes_json_patches        = null
    kubernetes_namespace           = "authentik"
    kubernetes_replicas            = 1
    kubernetes_service_type        = "ClusterIP"
    log_level                      = "debug"
    object_naming_template         = "ak-outpost-%(name)s"
    refresh_interval               = "minutes=5"
  })
  protocol_providers = [
    module.proxy_alertmanager.proxy_provider.id,
    module.proxy_longhorn.proxy_provider.id,
    module.proxy_pihole.proxy_provider.id,
    module.proxy_prometheus.proxy_provider.id,
    module.proxy_traefik_homelab.proxy_provider.id,

    module.proxy_lidarr.proxy_provider.id,
    module.proxy_prowlarr.proxy_provider.id,
    module.proxy_radarr.proxy_provider.id,
    module.proxy_sabnzbd.proxy_provider.id,
    module.proxy_sonarr.proxy_provider.id,

    module.proxy_home_assistant.proxy_provider.id
  ]
}
