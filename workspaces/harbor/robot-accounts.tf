resource "harbor_robot_account" "ci_robot_user" {
  name   = split("$", data.bitwarden_secret.harbor_robot_username.value)[1]
  level  = "system"
  secret = data.bitwarden_secret.harbor_robot_password.value

  permissions {
    kind      = "project"
    namespace = "build-cache"

    access {
      action   = "create"
      resource = "artifact"
    }
    access {
      action   = "create"
      resource = "artifact-label"
    }
    access {
      action   = "create"
      resource = "immutable-tag"
    }
    access {
      action   = "create"
      resource = "label"
    }
    access {
      action   = "create"
      resource = "sbom"
    }
    access {
      action   = "create"
      resource = "tag"
    }
    access {
      action   = "delete"
      resource = "artifact"
    }
    access {
      action   = "delete"
      resource = "artifact-label"
    }
    access {
      action   = "delete"
      resource = "label"
    }
    access {
      action   = "delete"
      resource = "tag"
    }
    access {
      action   = "list"
      resource = "artifact"
    }
    access {
      action   = "list"
      resource = "immutable-tag"
    }
    access {
      action   = "list"
      resource = "label"
    }
    access {
      action   = "list"
      resource = "repository"
    }
    access {
      action   = "list"
      resource = "tag"
    }
    access {
      action   = "pull"
      resource = "repository"
    }
    access {
      action   = "push"
      resource = "repository"
    }
    access {
      action   = "read"
      resource = "artifact"
    }
    access {
      action   = "read"
      resource = "artifact-addition"
    }
    access {
      action   = "read"
      resource = "label"
    }
    access {
      action   = "read"
      resource = "project"
    }
    access {
      action   = "read"
      resource = "repository"
    }
    access {
      action   = "read"
      resource = "sbom"
    }
    access {
      action   = "update"
      resource = "label"
    }
    access {
      action   = "update"
      resource = "repository"
    }
  }
  permissions {
    kind      = "project"
    namespace = "library"

    access {
      action   = "create"
      resource = "artifact"
    }
    access {
      action   = "create"
      resource = "artifact-label"
    }
    access {
      action   = "create"
      resource = "immutable-tag"
    }
    access {
      action   = "create"
      resource = "label"
    }
    access {
      action   = "create"
      resource = "sbom"
    }
    access {
      action   = "create"
      resource = "tag"
    }
    access {
      action   = "delete"
      resource = "artifact"
    }
    access {
      action   = "delete"
      resource = "artifact-label"
    }
    access {
      action   = "delete"
      resource = "label"
    }
    access {
      action   = "delete"
      resource = "tag"
    }
    access {
      action   = "list"
      resource = "artifact"
    }
    access {
      action   = "list"
      resource = "immutable-tag"
    }
    access {
      action   = "list"
      resource = "label"
    }
    access {
      action   = "list"
      resource = "repository"
    }
    access {
      action   = "list"
      resource = "tag"
    }
    access {
      action   = "pull"
      resource = "repository"
    }
    access {
      action   = "push"
      resource = "repository"
    }
    access {
      action   = "read"
      resource = "artifact"
    }
    access {
      action   = "read"
      resource = "artifact-addition"
    }
    access {
      action   = "read"
      resource = "label"
    }
    access {
      action   = "read"
      resource = "project"
    }
    access {
      action   = "read"
      resource = "repository"
    }
    access {
      action   = "read"
      resource = "sbom"
    }
    access {
      action   = "update"
      resource = "label"
    }
    access {
      action   = "update"
      resource = "repository"
    }
  }
}
