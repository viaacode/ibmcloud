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
  members_memory_allocation_mb = 2048
  members_disk_allocation_mb   = 10240
  members_cpu_allocation_count = 0
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_hetarchief-qas_dbmaster
  }
  whitelist {
    address = var.dwh_sources_ip
    description = "deewee etl process"
  }
  whitelist {
    address = "${local.zone_cse_source_address}/32"
    description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
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
  members_memory_allocation_mb = 12288
  members_disk_allocation_mb   = 61440
  members_cpu_allocation_count = 0
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_hetarchief-prd_dbmaster
  }
  whitelist {
    address = var.dwh_sources_ip
    description = "deewee etl process"
  }
  whitelist {
    address = "${local.zone_cse_source_address}/32"
    description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
  }
}

output "pg-connection-hetarchief-prd" {
  description = "Connection strings for the postgres databases"
  value = [ for r in  ibm_database.hetarchief-prd.connectionstrings: r.composed if r.name == "admin" ]
}
output "pg-connection-hetarchief-qas" {
  description = "Connection strings for the postgres databases"
  value = [ for r in  ibm_database.hetarchief-qas.connectionstrings: r.composed if r.name == "admin" ]
}
