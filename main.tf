terraform {
  required_version = ">= 0.14.0"
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = "~>1.14.0"
    }
  }
}

/**************FTNT**************
Firewall addresses that will be created/deleted based on the services
***************FTNT*************/
resource "fortios_firewall_address" "consul_service" {
  for_each = var.services

  name      = "${var.addrname_prefix}${each.value.id}${var.addrname_sufix}"
  subnet    = "${each.value.address} ${var.net_mask}"
  obj_type  = "ip"
  type      = "ipmask"

  lifecycle {
    create_before_destroy = true
  }
}

/**************FTNT**************
Firewall address groups that will be created/updated based on the variable of addrgrp_name_map and services
***************FTNT*************/
resource "fortios_firewall_addrgrp" "consul_service" {
  for_each = var.addrgrp_name_map

  name      = each.key

  dynamic "member" {
    for_each = length(setintersection(keys(local.consul_services), var.addrgrp_name_map[each.key])) == 0 ? ["none"] : flatten([
                for s_name in setintersection(keys(local.consul_services), var.addrgrp_name_map[each.key]) : [
                  for k, v in local.consul_services[s_name] : "${var.addrname_prefix}${v.id}${var.addrname_sufix}"
                ]
              ])
    content {
      name = member.value
    }
  }

  depends_on = [
    fortios_firewall_address.consul_service
  ]
}

locals {
  consul_services = {
    for id, s in var.services : s.name => s...
  }
}
