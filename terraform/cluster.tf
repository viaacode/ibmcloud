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

resource ibm_container_vpc_alb_create alb {
  cluster = ibm_container_vpc_cluster.give.id
  type = "private"
  zone = var.zone
  resource_group_id = ibm_resource_group.shared.id
  enable = "true"
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
  worker_count      = "5"
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
