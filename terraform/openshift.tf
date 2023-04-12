variable "ibm_openshift_net" {
  description = "subnet for the rhos openshift cluster"
}

resource "ibm_is_subnet" "openshift-net" {
  for_each = var.zones
  name = "openshift-net-${each.key}"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = each.value
  ipv4_cidr_block = var.ibm_openshift_net[each.value]
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  public_gateway = ibm_is_public_gateway.public-gateway[each.value].id
}

resource "ibm_resource_instance" "regbackup" {
  name     = "regbackup"
  service  = "cloud-object-storage"
  plan     = "standard"
  location = "global"
}

resource "ibm_container_vpc_cluster" "meemoo2" {
  name              = "meemoo2"
  vpc_id            = ibm_is_vpc.dc-ibm.id
  kube_version         = "4.10.53_openshift"
    flavor            = "bx2.8x32"
  worker_count      = "7"
  cos_instance_crn  = ibm_resource_instance.regbackup.id
  resource_group_id = ibm_resource_group.shared.id
  zones {
         subnet_id = ibm_is_subnet.openshift-net[var.zone].id
         name = var.zone
      }
  disable_public_service_endpoint = true
  wait_for_worker_update = true
  wait_till = "MasterNodeReady"
  }

  resource "ibm_container_vpc_worker_pool" "infra-workers" {
    cluster = ibm_container_vpc_cluster.meemoo2.id
    worker_pool_name = "infra-workers"
    vpc_id            = ibm_is_vpc.dc-ibm.id
    flavor            = "bx2.4x16"
    worker_count = 2
    operating_system = "REDHAT_8_64"
    dynamic "zones" {
      for_each = toset(["eu-de-2"])
      content {
        subnet_id = ibm_is_subnet.openshift-net[zones.value].id
        name = zones.key
        }
      }
  }
