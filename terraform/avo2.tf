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
  group {
    group_id = "member"
    memory {
      allocation_mb = 1024
    }
    disk {
      allocation_mb = 7168
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_events-qas_dbmaster
  }
  users {
    name = "dwhreader"
    password = var.password_db_dwhreader
  }
  dynamic "allowlist" {
    for_each = ibm_is_vpc.dc-ibm.cse_source_addresses
    content {
      address = "${allowlist.value.address}/32"
      description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${allowlist.value.zone_name}"
    }
  }
  allowlist {
    address = var.dwh_sources_ip
    description = "deewee ETL process"
  }
  allowlist {
    address = var.tableau_ip_1
    description = "IP 1 tableau"
  }
  allowlist {
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
  group {
    group_id = "member"
    memory {
      allocation_mb = 1024
    }
    disk {
      allocation_mb = 51200
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_events_dbmaster
  }
  allowlist {
    address = var.dwh_sources_ip
    description = "deewee ETL process"
  }
  dynamic "allowlist" {
    for_each = ibm_is_vpc.dc-ibm.cse_source_addresses
    content {
      address = "${allowlist.value.address}/32"
      description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${allowlist.value.zone_name}"
    }
  }
  allowlist {
    address = var.tableau_ip_1
    description = "IP 1 tableau"
  }
  allowlist {
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
  group {
    group_id = "member"
    memory {
      allocation_mb = 1024
    }
    disk {
      allocation_mb = 5120
    }
    cpu {
      allocation_count = 0
    }
  }
  service_endpoints            = "public-and-private"
  users {
    name = "dbmaster"
    password = var.password_db_avo2-qas_dbmaster
    type = "database"
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
  group {
    group_id = "member"
    memory {
      allocation_mb = 4096
    }
    disk {
      allocation_mb = 25600
    }
    cpu {
      allocation_count = 0
    }
  }
   service_endpoints            = "public-and-private"
   users {
     name = "dbmaster"
     password = var.password_db_avo2_dbmaster
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
