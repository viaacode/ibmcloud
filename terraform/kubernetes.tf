variable "ibm_kubernetes_net" {
  description = "subnet for the rhos openshift cluster"
  type = map
}
variable "kubernetes_zones" {
  description = "zones in which to create worker nodes"
  type = set(string)
}

resource "ibm_is_subnet" "kubernetes-net" {
  for_each = var.zones
  name = "kubernetes-net-${each.key}"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = each.value
  ipv4_cidr_block = var.ibm_kubernetes_net[each.value]
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  public_gateway = ibm_is_public_gateway.public-gateway[each.value].id
}

resource "ibm_container_vpc_cluster" "give" {
  name              = "give"
  vpc_id            = ibm_is_vpc.dc-ibm.id
  kube_version      = "1.25.9"
  flavor            = "bx2.8x32"
  worker_count      = "2"
  resource_group_id = ibm_resource_group.shared.id
  disable_public_service_endpoint = true
  wait_for_worker_update = true
  wait_till = "MasterNodeReady"
  dynamic "zones" {
    for_each = var.kubernetes_zones
    content {
      subnet_id = ibm_is_subnet.kubernetes-net[zones.value].id
      name = zones.key
      }
    }
}

# Our cluster has two ALB's in zone 1 probably due to historical reasons. Here we leave the first one disabled with a dirty hack
resource "ibm_container_vpc_alb" "private" {
    for_each = toset([for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"]=="private" && lb["id"] != "private-cr${ibm_container_vpc_cluster.give.id}-alb1"])
    alb_id = each.value
    enable = true
}

resource "ibm_container_vpc_alb" "public" {
    for_each = toset([ for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"] == "public" ])
    alb_id = each.value
    enable = false
}

output "private_loadbalancer" {
  value = [ for lb in ibm_container_vpc_cluster.give.albs : lb["id"] if lb["alb_type"] == "private" ]
}
