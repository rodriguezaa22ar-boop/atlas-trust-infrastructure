package atlas.authz

default decision = "unsupported"

decision = "unsupported" {
  not input.capability.id
}

decision = "not_in_scope" {
  input.capability.id
  input.scope.status == "out_of_scope"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "read"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "import"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "verify"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.capability.id == "atlas.public_export.check"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.scope.name == "public_trust"
}

decision = "deny" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.capability.id != "atlas.public_export.check"
  input.scope.name != "public_trust"
}

decision = "approval_required" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "bounded_exec"
  input.approval.status != "approved"
}

decision = "approval_required" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "mutate"
  input.approval.status != "approved"
}

decision = "approval_required" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "admin"
  input.approval.status != "approved"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "bounded_exec"
  input.approval.status == "approved"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "mutate"
  input.approval.status == "approved"
}

decision = "allow" {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "admin"
  input.approval.status == "approved"
}
