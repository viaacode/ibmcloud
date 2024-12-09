variable "password_db_events-qas_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_events-qas_dbmaster" {
  type = string
  description = "database hasura user password"
}

resource "ibm_database" "pg-events-qas" {
  name                         = "pg-events-qas"
  resource_group_id            = ibm_resource_group.qas.id
  service                      = "databases-for-postgresql"
  version                      = "15"
  plan                         = "standard"
  location                     =  var.location
  ## Temporary ignore password changes because of new policy requirements
  #adminpassword               = var.password_db_avo2-qas_admin
  adminpassword                = "dummy_temp_15_32_char"
  users {
    name = "dbmaster"
    #password = var.password_db_avo2-qas_dbmaster
    password = "dummy_temp_15_32_char"
  }
  lifecycle {
    ignore_changes = [ adminpassword, users ]
  }
  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 7168
    }
    cpu {
      allocation_count = 0
    }
  }
   service_endpoints            = "public-and-private"
}
variable "password_db_events_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_events_dbmaster" {
  type = string
  description = "database hasura user password"
}

resource "ibm_database" "pg-events-prd" {
  name                         = "pg-events-prd"
  resource_group_id            = ibm_resource_group.prd.id
  service                      = "databases-for-postgresql"
  version                      = "15"
  plan                         = "standard"
  location                     =  var.location
  ## Temporary ignore password changes because of new policy requirements
  #adminpassword               = var.password_db_events_admin
  adminpassword                = "dummy_temp_15_32_char"
  users {
    name = "dbmaster"
    #password = var.password_db_events_dbmaster
    password = "dummy_temp_15_32_char"
  }
  lifecycle {
    ignore_changes = [ adminpassword, users ]
  }
  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 61440
    }
    cpu {
      allocation_count = 0
    }
  }
   service_endpoints            = "public-and-private"
}
variable "password_db_avo2-qas_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_avo2-qas_dbmaster" {
  type = string
  description = "database hasura user password"
}

resource "ibm_database" "pg-avo-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "pg-avo-qas"
  service                      = "databases-for-postgresql"
  version                      = "13"
  plan                         = "standard"
  location                     =  var.location
  ## Temporary ignore password changes because of new policy requirements
  #adminpassword               = var.password_db_avo2-qas_admin
  adminpassword                = "dummy_temp_15_32_char"
  users {
    name = "dbmaster"
    #password = var.password_db_avo2-qas_dbmaster
    password = "dummy_temp_15_32_char"
  }
  lifecycle {
    ignore_changes = [ adminpassword, users ]
  }
  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 6144
    }
    cpu {
      allocation_count = 0
    }
  }
   service_endpoints            = "private"
}
variable "password_db_avo2_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_avo2_dbmaster" {
  type = string
  description = "database hasura user password"
}#
resource "ibm_database" "pg-avo-prd" {
  resource_group_id            = ibm_resource_group.prd.id
  name                         = "pg-avo-prd"
  service                      = "databases-for-postgresql"
  version                      = "13"
  plan                         = "standard"
  location                     =  var.location
  key_protect_instance         = "none"    # TODO waarom staat dit hier (en bijv. niet in qas ?)
  key_protect_key              = "none"
  ## Temporary ignore password changes because of new policy requirements
  #adminpassword               = var.password_db_avo2_admin
  adminpassword                = "dummy_temp_15_32_char"
  users {
    name = "dbmaster"
    #password = var.password_db_avo2_dbmaster
    password = "dummy_temp_15_32_char"
  }
  lifecycle {
    ignore_changes = [ adminpassword, users ]
  }
  group {
    group_id = "member"
    memory {
      allocation_mb = 8192
    }
    disk {
      allocation_mb = 40960
    }
    cpu {
      allocation_count = 0
    }
  }
   service_endpoints            = "public-and-private"   # TODO make private
}
