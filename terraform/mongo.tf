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
  group {
    group_id = "member"
    memory {
      allocation_mb = 1152
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

resource "ibm_database" "give-mongo-qas" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "mg-give-services-qas"
  service                      = "databases-for-mongodb"
  plan                         = "standard"
  location                     =  var.location
  version                      = "4.4"
  adminpassword                = var.password_db_mongo-qas_admin
  group {
    group_id = "member"
    memory {
      allocation_mb = 1152
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

resource "ibm_database" "give-mongo-int" {
  resource_group_id            = ibm_resource_group.qas.id
  name                         = "mg-give-services-int"
  service                      = "databases-for-mongodb"
  plan                         = "standard"
  location                     =  var.location
  version                      = "4.4"
  adminpassword                = var.password_db_avo2-qas_admin
  group {
    group_id = "member"
    memory {
      allocation_mb = 1152
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
