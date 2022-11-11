resource "ibm_resource_group" "prd" {
  name = "prd"                                                    
}    

resource "ibm_resource_group" "qas" {
  name = "qas"                                                    
}    

resource "ibm_resource_group" "shared" {
  name = "shared"
}


