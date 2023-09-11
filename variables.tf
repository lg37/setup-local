variable "RG_NAME" {
  type    = string
  default = "agent-rg"
}

variable "VNET_NAME" {
  type    = string
  default = "agent-vnet"
}

variable "tenant_id" {
  type    = string
  default = "72202515-4fcd-4520-8e82-526bfdc173c2"
}

variable "subscription_id" {
  type    = string
  default = "2e0dc74a-7ced-40d0-ad02-4275897598a5" # LG-payg
}

variable "tf-kv" {
  type    = string
  default = "lgbackend99-kv"
}

variable "backend_storage_account" {
  type    = string
  default = "tfstatelgsa1"
}