variable "datacenter" {
    default = "fra02"
}

variable "location" {
  default = "eu-de"
}

variable "zone" {
  default = "eu-de-1"
}

variable "viaa_dc_subnet" {
  type = string
  description = "external IP address of outgoing traffic from the VIAA datacenter"
}

variable "ssh_keys" {
  type = map
  description = "map of sshkeys with their label { <label> = \"ssh-rsa .....\" }"
}

variable "ibm_vpc_address_prefix" {
  type = string
}

variable "meemoo_dco_publicip" {
  description = "public IP address of the memmoo ipsec vpn endpoint in dco"
  type = string
}

variable "meemoo_dcg_publicip" {
  description = "public IP address of the memmoo ipsec vpn endpoint in dcg"
  type = string
}

variable "meemoo_dco_cidr" {
  description = "traffic selector for the meemoo dco side of the ipsec vpn"
  type = string
}

variable "meemoo_dcg_cidr" {
  description = "traffic selector for the meemoo dcg side of the ipsec vpn"
  type = string
}

variable "ipsec_vpn_psk" {
  description = "ike preshared key for ipsec vpn"
}

variable "ibm_openshift_net" {
  description = "subnet for the rhos openshift cluster"
}

variable "ibm_vpn_net" {
  description = "subnet for the for the vpc vpn gateway"
}

variable "ibm_vpe_net" {
  description = "subnet for the for the vpc virtual private endpoints"
}

resource "ibm_is_subnet" "vpe-net" {
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  resource_group = ibm_resource_group.shared.id
  name = "vpe-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  ipv4_cidr_block = var.ibm_vpe_net
}

resource "ibm_is_ssh_key" "keys" {
  for_each = var.ssh_keys
  name      = each.key
  public_key = each.value
  resource_group = ibm_resource_group.shared.id
}

resource "ibm_compute_ssh_key" "keys" {
  for_each = var.ssh_keys
  label      = each.key
  public_key = each.value
}

resource "ibm_resource_group" "shared" {
  name = "shared"
}

resource "ibm_resource_group" "qas" {
  name = "qas"
}

resource "ibm_resource_group" "prd" {
  name = "prd"
}

resource "ibm_network_vlan" "VIAA_public" {
  name       = "VIAA_public"
  datacenter = var.datacenter
  type       = "PUBLIC"
}

resource "ibm_network_vlan" "VIAA_private" {
  name       = "VIAA_private"
  datacenter = var.datacenter
  type       = "PRIVATE"
}

resource "ibm_security_group" "ipsec" {
  name = "allow_ipsec"
}

resource "ibm_security_group_rule" "openvpn_in" {
  direction = "ingress"
  port_range_min = 1194
  port_range_max = 1194
  protocol = "udp"
  security_group_id = ibm_security_group.ipsec.id
}

resource "ibm_security_group_rule" "openvpn_out" {
  direction = "egress"
  port_range_min = 1194
  port_range_max = 1194
  protocol = "udp"
  security_group_id = ibm_security_group.ipsec.id
}
resource "ibm_security_group_rule" "ipsec_dco_in" {
  direction = "ingress"
  port_range_min = 500
  port_range_max = 500
  protocol = "udp"
  remote_ip = var.viaa_dc_subnet
  security_group_id = ibm_security_group.ipsec.id
}

resource "ibm_security_group_rule" "ipsec_dco_out" {
  direction = "egress"
  port_range_min = 500
  port_range_max = 500
  protocol = "udp"
  remote_ip = var.viaa_dc_subnet
  security_group_id = ibm_security_group.ipsec.id
}

resource "ibm_compute_vm_instance" "vm1" {
  hostname                 = "viaa"
  domain                   = "viaa.be"
  datacenter               = var.datacenter
  os_reference_code        = "DEBIAN_9_64"
  network_speed            = 100
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25]
  dedicated_acct_host_only = true
  local_disk               = false
  ssh_key_ids              = [for key in ibm_compute_ssh_key.keys: key.id]
  public_vlan_id           = ibm_network_vlan.VIAA_public.id
  private_vlan_id          = ibm_network_vlan.VIAA_private.id
}

# not managed by terraform while transitionong to VPC
#resource "ibm_container_cluster" "openshift" {
#  name = "meemoo"
#  kube_version = "3.11.161_openshift"
#  machine_type = "b3c.8x32"
#  hardware = "shared"
#  datacenter = var.datacenter
#  resource_group_id = ibm_resource_group.shared.id
#  private_vlan_id = ibm_network_vlan.VIAA_private.id
#  public_vlan_id = ibm_network_vlan.VIAA_public.id
#  public_service_endpoint = true
#  private_service_endpoint = true
#  default_pool_size = 2
#  disk_encryption = false
#}

resource "ibm_is_vpc" "dc-ibm" {
  resource_group = ibm_resource_group.shared.id
  name = "dc-ibm"
  classic_access = false
  address_prefix_management = "manual"
}

resource "ibm_is_subnet" "vpn-net" {
  name = "vpn-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  ipv4_cidr_block = var.ibm_vpn_net
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
}

resource "ibm_is_vpn_gateway" "vpn-gateway" {
  name   = "vpn-gateway"
  subnet = ibm_is_subnet.vpn-net.id
  mode   = "route"
  resource_group = ibm_resource_group.shared.id
}

output "vpn-public-ip" {
  description = "Public IP addresses of the VPN gateway for the dc-ibm VPC"
  value = <<EOT
  ${ibm_is_vpn_gateway.vpn-gateway.public_ip_address}
  ${ibm_is_vpn_gateway.vpn-gateway.public_ip_address2}
  EOT
}

# The source address for traafic flowing from the VPC to private service
# endpoints and callsic infrastructure. Is needed for adding to the whitelist
# of IBM cloud database services.
# The cse_soure_address attribute exposes the SNAT address for all zones. Below
# the source address for our zone is selected from the list.
locals {
 zone_cse_source_address = ibm_is_vpc.dc-ibm.cse_source_addresses[
   index(ibm_is_vpc.dc-ibm.cse_source_addresses[*].zone_name,var.zone)
 ]["address"]
}

resource "ibm_is_ike_policy" "ike-meemoo-dc" {
    name = "ike-meemoo-dc"
    authentication_algorithm = "sha1"
    encryption_algorithm = "aes128"
    dh_group = 2
    ike_version = 1
    resource_group = ibm_resource_group.shared.id
}

resource "ibm_is_ipsec_policy" "ipsec-meemoo-dc" {
    name = "ipsec-meemoo-dc"
    authentication_algorithm = "sha1"
    encryption_algorithm = "aes128"
    pfs = "group_2"
    resource_group = ibm_resource_group.shared.id
}

resource "ibm_is_vpn_gateway_connection" "vpn-meemoo-dcg" {
  name          = "vpn-meemoo-dcg"
  vpn_gateway   = ibm_is_vpn_gateway.vpn-gateway.id
  peer_address  = var.meemoo_dcg_publicip
  preshared_key = var.ipsec_vpn_psk
  local_cidrs = [ ibm_is_vpc_address_prefix.dc-ibm-prefix.cidr, "166.8.0.0/14" ]
  peer_cidrs = [ var.meemoo_dcg_cidr ]
  admin_state_up = true
  ike_policy = ibm_is_ike_policy.ike-meemoo-dc.id
  ipsec_policy = ibm_is_ipsec_policy.ipsec-meemoo-dc.id
}

resource "ibm_is_vpn_gateway_connection" "vpn-meemoo-dco" {
  name          = "vpn-meemoo-dco"
  vpn_gateway   = ibm_is_vpn_gateway.vpn-gateway.id
  peer_address  = var.meemoo_dco_publicip
  preshared_key = var.ipsec_vpn_psk
  local_cidrs = [ibm_is_vpc_address_prefix.dc-ibm-prefix.cidr, "166.8.0.0/14" ]
  peer_cidrs = [var.meemoo_dco_cidr]
  admin_state_up = true
  ike_policy = ibm_is_ike_policy.ike-meemoo-dc.id
  ipsec_policy = ibm_is_ipsec_policy.ipsec-meemoo-dc.id
}

resource "ibm_is_vpc_routing_table" "dc-ibm-rt" {
    vpc = ibm_is_vpc.dc-ibm.id
    name = "dc-ibm-rt"
}

# This fails: created manualy or with te api
# https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2270
resource "ibm_is_vpc_routing_table_route" "route-meemoo-dcg" {
  routing_table = ibm_is_subnet.vpn-net.routing_table
  name        = "route-meemoo-dcg"
  vpc         = ibm_is_vpc.dc-ibm.id
  zone        = var.zone
  destination = var.meemoo_dcg_cidr
  next_hop    = element(split("/", ibm_is_vpn_gateway_connection.vpn-meemoo-dcg.id), 1)
}

resource "ibm_is_vpc_routing_table_route" "route-meemoo-dco" {
  routing_table = ibm_is_subnet.vpn-net.routing_table
  name        = "route-meemoo-dco"
  vpc         = ibm_is_vpc.dc-ibm.id
  zone        = var.zone
  destination = var.meemoo_dco_cidr
  next_hop    = element(split("/", ibm_is_vpn_gateway_connection.vpn-meemoo-dco.id), 1)
}

resource "ibm_is_public_gateway" "rhos-public-gateway" {
    resource_group = ibm_resource_group.shared.id
    name = "public-gateway"
    vpc = ibm_is_vpc.dc-ibm.id
    zone = var.zone
    #floating_ip = [ibm_is_floating_ip.public-ip.id]
}

resource "ibm_is_security_group_rule" "allow_dco" {
  group      = ibm_is_vpc.dc-ibm.default_security_group
  direction  = "inbound"
  remote     = var.meemoo_dco_cidr
}

resource "ibm_is_security_group_rule" "allow_dcg" {
  group      = ibm_is_vpc.dc-ibm.default_security_group
  direction  = "inbound"
  remote     = var.meemoo_dcg_cidr
}

resource "ibm_is_subnet" "openshift-net" {
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  resource_group = ibm_resource_group.shared.id
  name = "openshift-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  public_gateway = ibm_is_public_gateway.rhos-public-gateway.id
  ipv4_cidr_block = var.ibm_openshift_net
}

resource "ibm_is_vpc_address_prefix" "dc-ibm-prefix" {
  name = "dc-ibm-prefix"
  zone = var.zone
  vpc = ibm_is_vpc.dc-ibm.id
  cidr = var.ibm_vpc_address_prefix
}

resource "ibm_is_instance" "vm-vpc" {
  resource_group = ibm_resource_group.shared.id
  name = "vm-vpc"
  profile = "cx2-2x4"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  image = "r010-7b4a1103-c5ed-4a14-87c0-5f75b9f3c86a"
  primary_network_interface {
        subnet = ibm_is_subnet.openshift-net.id
  }
  keys              = [for key in ibm_is_ssh_key.keys: key.id]
}
