variable "vpn_routes" {
  description = "Configures which vpn connection is used, main or backup"
  type = map
}

variable "location" {
  default = "eu-de"
}

variable "zone" {
  default = "eu-de-1"
}

variable "zones" {
  type = set(string)
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
  type = map
}

variable "ibm_vpn_net" {
  description = "subnet for the vpc vpn gateway"
  type = map
}

variable "ibm_vpe_net" {
  description = "subnet for the vpc virtual private endpoints"
  type = map
}

resource "ibm_is_subnet" "vpe-net" {
  for_each = var.zones
  name = "vpe-net-${each.key}"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = each.value
  ipv4_cidr_block = var.ibm_vpe_net[each.value]
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
  for_each = var.zones
  name = "vpn-net-${each.key}"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = each.value
  ipv4_cidr_block = var.ibm_vpn_net[each.value]
  resource_group = ibm_resource_group.shared.id
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
}

resource "ibm_is_vpn_gateway" "vpn-gateway" {
  for_each = var.zones
  name   = "vpn-gateway-${each.key}"
  subnet = ibm_is_subnet.vpn-net[each.value].id
  mode   = "route"
  resource_group = ibm_resource_group.shared.id
}

# By IBM design, the numerically lowest VPN public IP is the primary address
# and the other one the secondary. Below we sort the IP address, but pad the
# compposing numbers first to 3 digits in order to have the string sort behave
# as a numerical sort. The padding is removed again before printing.
output "vpn-public-ips" {
  description = "Public IP addresses of the VPN gateway for the dc-ibm VPC"
  value = {
    for zone in var.zones: zone => [
      for i,ip in sort([
        for k,v in ibm_is_vpn_gateway.vpn-gateway[zone]: join(".",tolist(formatlist("%3d",split(".",v)))) if substr(k,0,17) == "public_ip_address"
      ]): format("%s public IP: %s", i == 0 ? "primary": "secondary", replace(ip, " ",""))
    ]
  }
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
 zones = tolist(var.zones)
 meemoo_routes = flatten([ for zone in  var.zones  :
      [ for meemoo_dc in values(var.vpn_routes) : {
          zone = zone
          meemoo_dc = meemoo_dc
          vpn_conn_zone = zone
          vpn_backup_con_zone =  local.zones[ index(local.zones, zone) == 0 ? length(local.zones) - 1 : index(local.zones, zone) -1 ]
      }]
  ])
 meemoo_vpncons = flatten([ for zone in var.zones:
      [ for endpoint in keys(var.vpn_connection): {
          zone = zone
          endpoint = endpoint
          parameters = var.vpn_connection[endpoint]
      }]
  ])
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
  for_each = { for entry in local.meemoo_vpncons: "${entry.endpoint}-${entry.zone}" => entry }
  name          = "vpn-meemoo-${each.key}"
  admin_state_up = contains(values(var.vpn_routes), each.value.endpoint)
  vpn_gateway   = ibm_is_vpn_gateway.vpn-gateway[each.value.zone].id
  peer_address  = each.value.parameters["publicip"]
  preshared_key = each.value.parameters["psk"]
  ike_policy = ibm_is_ike_policy.ike-meemoo-dc.id
  ipsec_policy = ibm_is_ipsec_policy.ipsec-meemoo-dc.id
}

resource "ibm_is_vpc_routing_table" "dc-ibm-rt" {
    vpc = ibm_is_vpc.dc-ibm.id
    name = "dc-ibm-rt"
}


resource "ibm_is_vpc_routing_table_route" "route-meemoo-dc" {
  for_each =  { for entry in local.meemoo_routes: "${entry.meemoo_dc}-${entry.zone}" => entry }
  routing_table = ibm_is_vpc_routing_table.dc-ibm-rt.routing_table
  name        = "meemoo-${each.key}"
  vpc         = ibm_is_vpc.dc-ibm.id
  zone        = each.value.zone
  destination = var.vpn_connection[each.value.meemoo_dc]["cidr"][0]
  next_hop    = element(split("/", ibm_is_vpn_gateway_connection.vpn-connections["${each.value.meemoo_dc}-${each.value.vpn_conn_zone}"].id), 1)
}

resource "ibm_is_floating_ip" "public-gateway-ip" {
  for_each = var.zones
  name = "public-gateway-ip-${each.key}"
  zone = each.value
}

resource "ibm_is_public_gateway" "public-gateway" {
  for_each = var.zones
  resource_group = ibm_resource_group.shared.id
  name = "public-gateway-${each.key}"
  vpc = ibm_is_vpc.dc-ibm.id
  zone = each.value
  floating_ip = {
    id = ibm_is_floating_ip.public-gateway-ip[each.value].id
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
  for_each = var.zones
  name = "dc-ibm-prefix-${each.key}"
  zone = each.value
  vpc = ibm_is_vpc.dc-ibm.id
  cidr = var.ibm_vpc_address_prefix[each.value]
}
