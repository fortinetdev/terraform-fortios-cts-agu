variable "services" {
  description = "Consul services monitored by Consul-Terraform-Sync"
  type = map(
    object({
      id        = string
      name      = string
      kind      = string
      address   = string
      port      = number
      meta      = map(string)
      tags      = list(string)
      namespace = string
      status    = string

      node                  = string
      node_id               = string
      node_address          = string
      node_datacenter       = string
      node_tagged_addresses = map(string)
      node_meta             = map(string)

      cts_user_defined_meta = map(string)
    })
  )
}

variable "addrname_prefix" {
  description = "(Optional)Prefix added to each address name"
  type        = string
  default     = ""
}

variable "addrname_sufix" {
  description = "(Optional)Sufix added to each address name"
  type        = string
  default     = ""
}

variable "net_mask" {
  description = "(Optional)Net mask for firewall address"
  type        = string
  default     = "255.255.255.255"
}

variable "addrgrp_name_map" {
  description = "Map of Firewall Address Group name to services"
  type        = map(list(string))
}

