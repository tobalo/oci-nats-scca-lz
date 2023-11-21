terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

resource "oci_identity_domain" "domain" {
  compartment_id            = var.compartment_id
  description               = var.domain_description
  display_name              = var.domain_display_name
  home_region               = var.domain_home_region
  license_type              = var.domain_license_type
  admin_email               = var.domain_admin_email
  admin_first_name          = var.domain_admin_first_name
  admin_last_name           = var.domain_admin_last_name
  admin_user_name           = var.domain_admin_user_name
  is_hidden_on_login        = var.domain_is_hidden_on_login
  is_notification_bypassed  = var.domain_is_notification_bypassed
  is_primary_email_required = var.domain_is_primary_email_required
}


resource "oci_identity_domain_replication_to_region" "domain_replication_to_region" {
  count          = var.enable_domain_replication ? 1 : 0
  domain_id      = oci_identity_domain.domain.id
  replica_region = var.domain_replica_region
}

locals {
  groups = {
    dynamic_groups = [for k, v in var.dynamic_groups : "-y ${v.dynamic_group_name} \"${v.matching_rule}\""]
  }
}
resource "null_resource" "groups" {
  count = length(var.group_names) != 0 ? 1 : 0

  triggers = {
    domain_id   = oci_identity_domain.domain.id
    group_names = "${join(",", var.group_names)}"
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "pip3 install -r scripts/requirements.txt"
    on_failure  = continue
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "python3 scripts/manage_identity_domain.py -d ${oci_identity_domain.domain.id} -g ${join(" ", var.group_names)}"
    on_failure  = continue
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "python3 scripts/manage_identity_domain.py -d ${oci_identity_domain.domain.id} ${join(" ", local.groups.dynamic_groups)}"
    on_failure  = continue
  }
}
