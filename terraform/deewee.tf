variable "dwh_sources_ip" {            
  type = string                          
  description = "IP address of the deewee ETL host"
}

variable "password_db_dwhreader" {
  type = string
  description = "database dwhreader password"
}

variable "tableau_ip_1" {
  type = string
  description = "IP address 1 of tableau online"
}

variable "tableau_ip_2" {
  type = string
  description = "IP address 2 of tableau online"
}

