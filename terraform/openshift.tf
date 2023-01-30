variable "ibm_openshift_net" {
  description = "subnet for the rhos openshift cluster"
}

resource "ibm_is_subnet" "openshift-net" {
  name = "openshift-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  ipv4_cidr_block = var.ibm_openshift_net
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  public_gateway = ibm_is_public_gateway.public-gateway.id
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
  kube_version         = "4.8.51_openshift"
    flavor            = "bx2.8x32"
  worker_count      = "7"
  cos_instance_crn  = ibm_resource_instance.regbackup.id
  resource_group_id = ibm_resource_group.shared.id
  zones {
         subnet_id = ibm_is_subnet.openshift-net.id
         name = var.zone
      }
  disable_public_service_endpoint = true
  wait_for_worker_update = true
  wait_till = "MasterNodeReady"
  }
