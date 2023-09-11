variable "vm_name" {
  type    = string
  default = "dummyVM"
}

variable "vm_size" {
  type    = string
  default = "Standard_F2"
}
variable "rg" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "subnet_id" {
  type = string
}