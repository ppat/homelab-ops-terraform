resource "authentik_policy_binding" "group_binding" {
  count  = length(var.groups)
  group  = var.groups[count.index]
  target = authentik_application.application.uuid
  order  = count.index
}
