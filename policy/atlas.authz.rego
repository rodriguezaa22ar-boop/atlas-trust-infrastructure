package atlas.authz

default decision = "unsupported"

decision = "unsupported" if {
  not input.capability.id
}

decision = "not_in_scope" if {
  input.capability.id
  input.scope.status == "out_of_scope"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "read"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "import"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "verify"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.capability.id == "atlas.public_export.check"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.scope.name == "public_trust"
}

decision = "deny" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "export"
  input.capability.id != "atlas.public_export.check"
  input.scope.name != "public_trust"
}

decision = "approval_required" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "bounded_exec"
  input.approval.status != "approved"
}

decision = "approval_required" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "mutate"
  input.approval.status != "approved"
}

decision = "approval_required" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "admin"
  input.approval.status != "approved"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "bounded_exec"
  input.approval.status == "approved"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "mutate"
  input.approval.status == "approved"
}

decision = "allow" if {
  input.capability.id
  input.scope.status != "out_of_scope"
  input.capability.class == "admin"
  input.approval.status == "approved"
}
