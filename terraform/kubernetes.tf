variable "ibm_kubernetes_net" {
  description = "subnet for the rhos openshift cluster"
}

resource "ibm_is_subnet" "kubernetes-net" {
  name = "kubernetes-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  ipv4_cidr_block = var.ibm_kubernetes_net
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  public_gateway = ibm_is_public_gateway.public-gateway.id
}

resource "ibm_container_vpc_cluster" "give" {
  name              = "give"
  vpc_id            = ibm_is_vpc.dc-ibm.id
  kube_version      = "1.24.7"
  flavor            = "bx2.8x32"
  worker_count      = "2"
  resource_group_id = ibm_resource_group.shared.id
  zones {
         subnet_id = ibm_is_subnet.kubernetes-net.id
         name = var.zone
      }
  disable_public_service_endpoint = true
  wait_for_worker_update = true
  wait_till = "MasterNodeReady"
  }

resource "ibm_container_vpc_alb" "private" {
    alb_id = [ for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"] == "private" ][0]
    enable = true
}

resource "ibm_container_vpc_alb" "public" {
    alb_id = one([ for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"] == "public" ])
    enable = false
}

output "private_loadbalancer" {
  value = [ for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"] == "public" ][0]
}
