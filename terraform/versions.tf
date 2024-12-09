terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "= 1.71.3"  # Lock to v1.71 as v1.72 does no longer support postgres 13
    }
  }
  required_version = ">= 1.10.1"
}
