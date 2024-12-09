variable "password_db_postgres-int_admin" {
  type = string
}

variable "password_db_postgres-qas_admin" {
  type = string
}

variable "password_db_postgres-prd_admin" {
type = string
}

resource "ibm_database" "pg-give-services-int" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "pg-give-services-int"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     =  var.location
  version                      = "14"
  adminpassword                = var.password_db_postgres-int_admin

  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 10240
    }
    cpu {
      allocation_count = 0
    }
  }

  service_endpoints            = "private"
}

resource "ibm_database" "pg-give-services-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "pg-give-services-qas"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     =  var.location
  version                      = "14"
  adminpassword                = var.password_db_postgres-qas_admin

  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 17408
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "private"
}

resource "ibm_database" "pg-give-services-prd" {
  resource_group_id            = ibm_resource_group.prd.id
  name                         = "pg-give-services-prd"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     =  var.location
  version                      = "14"
  adminpassword                = var.password_db_postgres-prd_admin

  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 119808
    }
    cpu {
      allocation_count = 0
    }
  }

  service_endpoints            = "private"
}

