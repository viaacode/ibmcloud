variable "password_db_events-qas_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_events-qas_dbmaster" {
  type = string
  description = "database hasura user password"
}
resource "ibm_database" "events-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "events-qas"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     = var.location
  version                      = "11"
  adminpassword                = var.password_db_events-qas_admin
  members_memory_allocation_mb = 2048
  members_disk_allocation_mb   = 14336
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_events-qas_dbmaster
  }
  users {
    name = "dwhreader"
    password = var.password_db_dwhreader
  }
  whitelist {
    address = var.dwh_sources_ip
    description = "deewee ETL process"
  }
  whitelist {
    address = "${local.zone_cse_source_address}/32"
    description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
  }
  whitelist {
    address = var.tableau_ip_1
    description = "IP 1 tableau"
  }
  whitelist {
    address = var.tableau_ip_2
    description = "IP 2 tableau"
  }
}

variable "password_db_events_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_events_dbmaster" {
  type = string
  description = "database hasura user password"
}
resource "ibm_database" "events" {
  resource_group_id            = ibm_resource_group.prd.id
  name                         = "events"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     =  var.location
  version                      = "11"
  adminpassword                = var.password_db_events_admin
  members_memory_allocation_mb = 2048
  members_disk_allocation_mb   = 102400
  members_cpu_allocation_count = 0
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_events_dbmaster
  }
  whitelist {
    address = var.dwh_sources_ip
    description = "deewee ETL process"
  }
  whitelist {
    address = "${local.zone_cse_source_address}/32"
    description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
  }
  whitelist {
    address = var.tableau_ip_1
    description = "IP 1 tableau"
  }
  whitelist {
    address = var.tableau_ip_2
    description = "IP 2 tableau"
  }
}

variable "password_db_avo2-qas_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_avo2-qas_dbmaster" {
  type = string
  description = "database hasura user password"
}
resource "ibm_database" "avo2-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "avo2-qas"
  service                      = "databases-for-postgresql"
  plan                         = "standard"
  location                     =  var.location
  version                      = "11"
  adminpassword                = var.password_db_avo2-qas_admin
  members_memory_allocation_mb = 2048
  members_disk_allocation_mb   = 10240
  members_cpu_allocation_count = 0
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_avo2-qas_dbmaster
    type = "database"
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

variable "password_db_avo2_admin" {
  type = string
  description = "database admin password"
}
variable "password_db_avo2_dbmaster" {
  type = string
  description = "database hasura user password"
}
resource "ibm_database" "avo2" {
#  resource_group_id            = ibm_resource_group.prd.id
   name                         = "Databases for PostgreSQL-m1"
   service                      = "databases-for-postgresql"
   plan                         = "standard"
   location                     =  var.location
   version                      = "12"
   adminpassword                = var.password_db_avo2_admin
   members_memory_allocation_mb = 8192
   members_disk_allocation_mb   = 51200
   members_cpu_allocation_count = 0
#   groups {
#     group_id = "member"
#
#     memory {
#       allocation_mb = 8192
#     }
#
#     disk {
#       allocation_mb = 51200
#     }
#
#     cpu {
#       allocation_count = 0
#     }
#   }
   service_endpoints            = "public-and-private"
   users {
     name = "dbmaster"
     password = var.password_db_avo2_dbmaster
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
