variable "password_db_hetarchief-qas_dbmaster" {
  type = string
  description = "database hasura user password"
}
variable "password_db_hetarchief-qas_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_hetarchief-prd_dbmaster" {
  type = string
  description = "database hasura user password"
}
variable "password_db_hetarchief-prd_admin" {
  type = string
  description = "database admin password"
}
resource "ibm_database" "hetarchief-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "hetarchief-qas"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     = var.location
  version                      = "12"
  adminpassword                = var.password_db_hetarchief-qas_admin
  group {
    group_id = "member"
    memory {
      allocation_mb = 2048
    }
    disk {
      allocation_mb = 10240
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_hetarchief-qas_dbmaster
  }
  allowlist {
    address = var.dwh_sources_ip
    description = "deewee etl process"
  }
  dynamic "allowlist" {
    for_each = ibm_is_vpc.dc-ibm.cse_source_addresses
    content {
      address = "${allowlist.value.address}/32"
      description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${allowlist.value.zone_name}"
    }
  }
}

resource "ibm_database" "hetarchief-prd" {
  resource_group_id            = ibm_resource_group.prd.id
  name                         = "hetarchief-prd"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     = var.location
  version                      = "12"
  adminpassword                = var.password_db_hetarchief-prd_admin
  group {
    group_id = "member"
    memory {
      allocation_mb = 6144
    }
    disk {
      allocation_mb = 30720
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_hetarchief-prd_dbmaster
  }
  allowlist {
    address = var.dwh_sources_ip
    description = "deewee etl process"
  }
  dynamic "allowlist" {
    for_each = ibm_is_vpc.dc-ibm.cse_source_addresses
    content {
      address = "${allowlist.value.address}/32"
      description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${allowlist.value.zone_name}"
    }
  }
}

data "ibm_database_connection" "hetarchief-prd" {
  endpoint_type = "private"
  deployment_id = ibm_database.hetarchief-prd.id
  user_id = "admin"
  user_type = "database"
}
data "ibm_database_connection" "hetarchief-qas" {
  endpoint_type = "private"
  deployment_id = ibm_database.hetarchief-prd.id
  user_id = "admin"
  user_type = "database"
}

output "pg-connection-hetarchief-prd" {
  description = "Connection strings for the postgres databases"
  value = one(one(data.ibm_database_connection.hetarchief-prd.postgres).composed)
}
output "pg-connection-hetarchief-qas" {
  description = "Connection strings for the postgres databases"
  value = one(one(data.ibm_database_connection.hetarchief-qas.postgres).composed)
}
