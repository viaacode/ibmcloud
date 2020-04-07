variable "datacenter" {
    default = "fra02"
}

variable "location" {
  default = "eu-de"
}

variable "viaa_dc_ip" {
  type = string
  description = "external IP address of outgoing traffic from the VIAA datacenter"
}

variable "ssh_keys" {
  type = map
  description = "map of sshkeys with their label { <label> = \"ssh-rsa .....\" }"
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
  remote_ip = var.viaa_dc_ip
  security_group_id = ibm_security_group.ipsec.id
}

resource "ibm_security_group_rule" "ipsec_dco_out" {
  direction = "egress"
  port_range_min = 500
  port_range_max = 500
  protocol = "udp"
  remote_ip = var.viaa_dc_ip
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

resource "ibm_container_cluster" "openshift" {
  name = "meemoo"
  kube_version = "3.11.161_openshift"
  machine_type = "b3c.8x32"
  hardware = "shared"
  datacenter = var.datacenter
  resource_group_id = ibm_resource_group.shared.id
  private_vlan_id = ibm_network_vlan.VIAA_private.id
  public_vlan_id = ibm_network_vlan.VIAA_public.id
  public_service_endpoint = true
  private_service_endpoint = true
  default_pool_size = 2
  disk_encryption = false
}

