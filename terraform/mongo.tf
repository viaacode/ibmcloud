variable "password_db_mongo-qas_admin" {
  type = string
}
variable "password_db_mongo-prd_admin" {
  type = string
}
resource "ibm_database" "give-mongo-prd" {
  resource_group_id            = ibm_resource_group.prd.id
  name                         = "mg-give-services-prd"
  service                      = "databases-for-mongodb"
  plan                         = "standard"
  location                     =  var.location
  version                      = "4.4"
  adminpassword                = var.password_db_mongo-prd_admin
  members_memory_allocation_mb = 3456
  members_disk_allocation_mb   = 30720
  members_cpu_allocation_count = 0
  service_endpoints            = "private"
 # whitelist {
 #   address = var.dwh_sources_ip
 #   description = "deewee etl process"
 # }
 # whitelist {
 #   address = "${local.zone_cse_source_address}/32"
 #   description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
 # }
}

resource "ibm_database" "give-mongo-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "mg-give-services-qas"
  service                      = "databases-for-mongodb"
  plan                         = "standard"
  location                     =  var.location
  version                      = "4.4"
  adminpassword                = var.password_db_mongo-qas_admin
  members_memory_allocation_mb = 3456
  members_disk_allocation_mb   = 30720
  members_cpu_allocation_count = 0
  service_endpoints            = "private"
 # whitelist {
 #   address = var.dwh_sources_ip
 #   description = "deewee etl process"
 # }
 # whitelist {
 #   address = "${local.zone_cse_source_address}/32"
 #   description = "VPC ${ibm_is_vpc.dc-ibm.name}, zone: ${var.zone}"
 # }
}
resource "ibm_database" "give-mongo-int" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "mg-give-services-int"
  service                      = "databases-for-mongodb"
  plan                         = "standard"
  location                     =  var.location
  version                      = "4.4"
  adminpassword                = var.password_db_avo2-qas_admin
  members_memory_allocation_mb = 3456
  members_disk_allocation_mb   = 30720
  members_cpu_allocation_count = 0
  service_endpoints            = "private"
}
