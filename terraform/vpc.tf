variable "location" {
  default = "eu-de"
}

variable "zone" {
  default = "eu-de-1"
}

variable "viaa_dc_subnet" {
  type = string
  description = "external IP addresses of the meemoo datacenter"
}

variable "ssh_keys" {
  type = map
  description = "map of sshkeys with their label { <label> = \"ssh-rsa .....\" }"
}

variable "vpn_connection" {
  type = map
}

variable "ibm_vpc_address_prefix" {
  type = string
}

variable "ibm_vpn_net" {
  description = "subnet for the vpc vpn gateway"
}

variable "ibm_vpe_net" {
  description = "subnet for the vpc virtual private endpoints"
}

resource "ibm_is_subnet" "vpe-net" {
  name = "vpe-net"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = var.zone
  ipv4_cidr_block = var.ibm_vpe_net
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
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

output "vpn-public-ips" {
  description = "Public IP addresses of the VPN gateway for the dc-ibm VPC"
  value = [ for k,v in ibm_is_vpn_gateway.vpn-gateway: v if substr(k,0,17) == "public_ip_address" ]
}

# The source address for traffic flowing from the VPC to private service
# endpoints and classic infrastructure. Is needed for adding to the whitelist
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
    authentication_algorithm = "sha384"
    encryption_algorithm = "aes192"
    dh_group = 19
    ike_version = 2
    resource_group = ibm_resource_group.shared.id
}

resource "ibm_is_ipsec_policy" "ipsec-meemoo-dc" {
    name = "ipsec-meemoo-dc"
    authentication_algorithm = "sha256"
    encryption_algorithm = "aes256"
    pfs = "group_14"
    resource_group = ibm_resource_group.shared.id
}

resource "ibm_is_vpn_gateway_connection" "vpn-connections" {
  for_each = var.vpn_connection 
  name          = "vpn-meemoo-${each.key}"
  vpn_gateway   = ibm_is_vpn_gateway.vpn-gateway.id
  peer_address  = each.value["publicip"]
  preshared_key = each.value["psk"]
  local_cidrs = [ ibm_is_vpc_address_prefix.dc-ibm-prefix.cidr, "166.8.0.0/14" ]
  peer_cidrs = each.value["cidr"]
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
  destination = var.vpn_connection["dcg"]["cidr"][0]
  next_hop    = element(split("/", ibm_is_vpn_gateway_connection.vpn-connections["dcg"].id), 1)
}

resource "ibm_is_vpc_routing_table_route" "route-meemoo-dco" {
  routing_table = ibm_is_subnet.vpn-net.routing_table
  name        = "route-meemoo-dco"
  vpc         = ibm_is_vpc.dc-ibm.id
  zone        = var.zone
  destination = var.vpn_connection["dco"]["cidr"][0]
  next_hop    = element(split("/", ibm_is_vpn_gateway_connection.vpn-connections["dco"].id), 1)
}

resource "ibm_is_floating_ip" "public-gateway-ip" {
  name = "public-gateway-ip"
  zone = var.zone
}

resource "ibm_is_public_gateway" "public-gateway" {
    resource_group = ibm_resource_group.shared.id
    name = "public-gateway"
    vpc = ibm_is_vpc.dc-ibm.id
    zone = var.zone
    floating_ip = {
      id = ibm_is_floating_ip.public-gateway-ip.id
    }
}

resource "ibm_is_security_group_rule" "allow_dco" {
  group      = ibm_is_vpc.dc-ibm.default_security_group
  direction  = "inbound"
  remote     = var.vpn_connection["dco"]["cidr"][0]
}

resource "ibm_is_security_group_rule" "allow_dcg" {
  group      = ibm_is_vpc.dc-ibm.default_security_group
  direction  = "inbound"
  remote     = var.vpn_connection["dcg"]["cidr"][0]
}

resource "ibm_is_vpc_address_prefix" "dc-ibm-prefix" {
  name = "dc-ibm-prefix"
  zone = var.zone
  vpc = ibm_is_vpc.dc-ibm.id
  cidr = var.ibm_vpc_address_prefix
}
