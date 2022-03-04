## Fortinet FortiOS Address, Address Group Update (AGU) module for Consul Terraform Sync (CTS)

This Terraform module connects to FortiOS and creates Firewall addresses for each Consul service and updates address groups based on service names. Each address group will include all firewall addresses with the service names in variable `addrgrp_name_map`. Using the module in automation with [Consul Terraform Sync](https://www.consul.io/docs/nia) will dynamically add or remove service instances from the address group based on [Consul service discovery](https://www.consul.io/). 

This way FortiOS/FortiGate will be configured with the dynamically learned services IP addresses, thus allowing it to implement Firewall policies based on dynamically learned service information.

Using this Terraform module in conjunction with **consul-terraform-sync** enables teams to reduce manual ticketing processes and automate Day-2 operations related to application scale up/down in a way that is both declarative and repeatable across the organization.

#### Note: This Terraform module is designed to be used only with **consul-terraform-sync**

## Feature

The module dynamically creates, updates, and deletes Firewall address and address group based on service id and address.

Firewall address groups will be created based on the keys of variable `addrgrp_name_map`. The argument of `member` will be modified based on the services that each address group name is mapped to. Argument `member` will be set to `none` if all mapped services are removed. All address groups will never be deleted to avoid potential error that would occur when the address groups are referenced by other resources.

If there is a missing feature or a bug - - [open an issue](https://github.com/fortinetdev/terraform-fortios-cts-agu/issues/new)

## What is consul-terraform-sync?

The **consul-terraform-sync** runs as a daemon that enables a **publisher-subscriber** paradigm between **Consul** and **FortiOS** based devices to support **Network Infrastructure Automation (NIA)**. 

<p align="left">
<img width="500" src="https://raw.githubusercontent.com/fortinetdev/terraform-fortios-cts-agu/main/images/cts-agu-schematic.png"> </a>
</p>

* consul-terraform-sync **subscribes to updates from the Consul catalog** and executes one or more automation **"tasks"** with appropriate value of *service variables* based on those updates. **Consul-terraform-sync** leverages [Terraform](https://www.terraform.io/) as the underlying automation tool and utilizes the Terraform provider ecosystem to drive relevant change to the network infrastructure. 

* Each task consists of a runbook automation written as a compatible **Terraform module** using resources and data sources for the underlying network infrastructure provider.

Please refer to this [link](https://www.consul.io/docs/nia/installation/install) for getting started with **consul-terraform-sync**

## Requirements

* Install Consul and run a consul client. Please refer to this [Consul CLI Quick Start](https://learn.hashicorp.com/tutorials/consul/get-started?in=consul/getting-started)

* Install consul-terraform-sync. Please refer to this [Install Consul-Terraform-Sync](https://www.consul.io/docs/nia/installation/install)

* In FortiOS, no address group should exist with the same names as specified in variable `addrgrp_name_map`

* Firewall address `none` should exists and be configured with `0.0.0.0/32`


### Ecosystem Requirements

| Ecosystem | Version |
|-----------|---------|
| [consul](https://www.consul.io/downloads) | >= 1.7 |
| [consul-terraform-sync](https://www.consul.io/docs/nia) | >= 0.1.0 |
| [terraform](https://www.terraform.io) | >= 0.14 |

### Terraform Providers

| Name | Version |
|------|---------|
| fortinetdev/fortios | >= 1.14.0 |

## Compatibility
This module is meant for use with **consul-terraform-sync >= 0.1.0** and **Terraform >= 0.14** and **fortios provider versions >= 1.3.5**

-> The maximum number of supported address group `member` depends on the model of the FortiGate and version of FortiOS. The maximum address group member each address group will support can be validated on the [FortiOS maximum values document](https://docs.fortinet.com/max-value-table) under the `firewall.addrgrp:member` object.


## Usage
In order to use this module, you will need to install **consul-terraform-sync**, create a **"task"** with this Terraform module as a source within the task, and run **consul-terraform-sync**.

The users can subscribe to the services in the consul catalog and define the Terraform module which will be executed when there are any updates to the subscribed services using a **"task"**.

**~> Note:** It is recommended to have the [consul-terraform-sync config guide](https://www.consul.io/docs/nia/installation/configuration) for reference.
  
1. Download the **consul-terraform-sync** on a node which is highly available (preferably, a node running a consul client)
2. Add **consul-terraform-sync** to the PATH on that node
3. Check the installation
    ```
    $ consul-terraform-sync --version
    consul-terraform-sync v0.1.1 (4dc13b5)
    Compatible with Terraform >= 0.13.0, < 0.15
    ```
4. Create a config file **\<YOUR_CONFIG\>.hcl**, and a variable file **\<YOUR_VARIABLE\>.tfvars** if needed. Please note that this just an example. 
    
    task.hcl
    ```hcl
    log_level = "info"

    consul {
      address = <Consul agent address> # e.g. "localhost:8500"
    }

    driver "terraform" {
      log = true
      version = "0.14.0"
      required_providers {
        fortios = {
          source = "fortinetdev/fortios"
        }
      }
    }

    terraform_provider "fortios" {
        hostname     = <FortiOS address>
        token        = <Your token>
        insecure     = "true"
        vdom         = <Your vdom> 
    }

    task {
      name = <Task name> # "CTS-test"
      description = <Description of the task> #"Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync"
      source = "github.com/fortinetdev/terraform-fortios-cts-agu" # to be updated
      providers = ["fortios"]
      services = [<List of services>] # e.g. ["finance_workstations", "windows10", "windows11"]
      variable_files = [<List of variable files for this module with full path>] # e.g. ["/opt/fos-consul/consul_test.tfvars"]
    }
    ```
    consul_test.tfvars
    ```
    addrgrp_name_map = {
      "<Address group name 1>" : <List of services>, # e.g. "cts-finance" : ["finance_workstations"],
      "<Address group name 2>" : <List of services> # e.g. "cts-windows" : ["windows10", "windows11"]
    }
    ```
5. Start consul-terraform-sync
    ```
    $ consul-terraform-sync -config-file <YOUR CONFIG>.hcl
    ```
    For example:
    ```
    $ consul-terraform-sync -config-file tasks.hcl
    ```

**consul-terraform-sync is now subscribed to the Consul catalog. Any updates to the services identified in the task will result in updating the service groups in the FortiOS device** 


**~> Note:** If you are interested in how **consul-terraform-sync** works, please refer to this [section](#how-does-consul-terraform-sync-work).


## Inputs

| Name | Description | Type | Default | Required | Options |
|------|-------------|------|---------|:--------:|:-------:|
| addrname\_prefix | Prefix added to each address name | `string` | "" | No | N/A |
| addrname\_sufix | Sufix added to each address name | `string` | "" | No | N/A |
| net\_mask | Net mask for firewall address | `string` | "255.255.255.255" | No | N/A |
| addrgrp\_name\_map | Map of Firewall Address Group name to services | `string` | N/A | Yes | N/A  |
| services | Consul services monitored by consul-terraform-sync | <pre>map(<br>    object({<br>      id        = string<br>      name      = string<br>      kind      = string<br>      address   = string<br>      port      = number<br>      meta      = map(string)<br>      tags      = list(string)<br>      namespace = string<br>      status    = string<br><br>      node                  = string<br>      node_id               = string<br>      node_address          = string<br>      node_datacenter       = string<br>      node_tagged_addresses = map(string)<br>      node_meta             = map(string)<br><br>      cts_user_defined_meta             = map(string)<br>    })<br>  )</pre> | N/A | Yes | N/A |


## How does consul-terraform-sync work?

There are 2 aspects of consul-terraform-sync.
1. **Updates from Consul catalog:**
In the backend, consul-terraform-sync creates a blocking API query session with the Consul agent identified in the config to get updates from the Consul catalog. Consul-terraform-sync will get an update for the services in the consul catalog when any of the following service attributes are created, updated or deleted. These updates include service creation and deletion as well.
   * service id
   * service name
   * service kind
   * service address
   * service port
   * service meta
   * service tags
   * service namespace
   * service status
   * node
   * node id
   * node address
   * node datacenter
   * node tagged addresses
   * node meta
   * cts_user_defined_meta

   
2. **Managing the entire Terraform workflow:**
If a task is defined, one or more services are associated with the task, provider is declared in the task and a Terraform module is specified using the source field of the task, the following sequence of events will occur:
   1. consul-terraform-sync will install the required version of Terraform.
   2. consul-terraform-sync will install the required version of the Terraform provider defined in the config file and declared in the "task".
   3. A new directory "sync-tasks" with a sub-directory corresponding to each "task" will be created.  This is the reason for having strict guidelines around naming.
   4. Each sub-directory corresponds to a separate Terraform workspace. 
   5. Within each sub-directory corresponding a task, consul-terraform-sync will template a main.tf, variables.tf, variables.module.tf, terraform.tfvars, provider.tfvars, and terraform.tfvars.tmpl.
      * **main.tf:**
         * This file contains declaration for the required terraform and provider versions based on the task definition. 
         * In addition, this file has the module (identified by the 'source' field in the task) declaration with the input variables
         * Consul K/V is used as the backend state for this Terraform workspace.
      
         Example generated main.tf file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          terraform {
            required_version = ">= 0.13.0, < 0.15"
            required_providers {
              fortios = {
                source = "fortinetdev/fortios"
              }
            }
            backend "consul" {
              address = "localhost:8500"
              gzip    = true
              path    = "consul-terraform-sync/terraform"
            }
          }

          provider "fortios" {
            hostname = var.fortios.hostname
            insecure = var.fortios.insecure
            token    = var.fortios.token
            vdom     = var.fortios.vdom
          }

          # Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync
          module "CTS-test" {
            source   = "/home/xing/mainfolder/testing/hashicorp_consul/fos/fos_agu/fos_module"
            services = var.services

            addrgrp_name_map = var.addrgrp_name_map
          }

          ```
      * **variables.tf:**
        * This is `variables.tf` file defined in the module.
        
          Example generated `variables.tf` file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          # Service definition protocol v0
          variable "services" {
            description = "Consul services monitored by Consul Terraform Sync"
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

          variable "fortios" {
            default     = null
            description = "Configuration object for fortios"
            sensitive   = true
            type = object({
              hostname = string
              insecure = string
              token    = string
              vdom     = string
            })
          }
         ```
      * **variables.module.tf:**
        * This is `variables.module.tf` file defined in the module.
        
          Example generated `variables.module.tf` file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          variable "addrgrp_name_map" {
            default = null
            type = object({
              cts-finance = tuple([string])
              cts-windows = tuple([string, string])
            })
          }
         ```
      * **terraform.tfvars:**
        * This is the most important file generated by consul-terraform-sync.
        * This variables file is generated with the most updated values from Consul catalog for all the services identified in the task.
        * consul-terraform-sync updates this file with the latest values when the corresponding service gets updated in Consul catalog.
        
          Example terraform.tfvars file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          services = {
            "finance_workstations-1.xing-virtual-machine.dc1" : {
              id              = "finance_workstations-1"
              name            = "finance_workstations"
              kind            = ""
              address         = "192.168.5.11"
              port            = 0
              meta            = {}
              tags            = []
              namespace       = null
              status          = "passing"
              node            = "xing-virtual-machine"
              node_id         = "22ddbd29-0454-4726-b207-82418ac5b4e3"
              node_address    = "127.0.0.1"
              node_datacenter = "dc1"
              node_tagged_addresses = {
                lan      = "127.0.0.1"
                lan_ipv4 = "127.0.0.1"
                wan      = "127.0.0.1"
                wan_ipv4 = "127.0.0.1"
              }
              node_meta = {
                consul-network-segment = ""
              }
              cts_user_defined_meta = {}
            },
            "windows10-1.xing-virtual-machine.dc1" : {
              id              = "windows10-1"
              name            = "windows10"
              kind            = ""
              address         = "192.168.6.11"
              port            = 0
              meta            = {}
              tags            = []
              namespace       = null
              status          = "passing"
              node            = "xing-virtual-machine"
              node_id         = "22ddbd29-0454-4726-b207-82418ac5b4e3"
              node_address    = "127.0.0.1"
              node_datacenter = "dc1"
              node_tagged_addresses = {
                lan      = "127.0.0.1"
                lan_ipv4 = "127.0.0.1"
                wan      = "127.0.0.1"
                wan_ipv4 = "127.0.0.1"
              }
              node_meta = {
                consul-network-segment = ""
              }
              cts_user_defined_meta = {}
            },
            "windows11-1.xing-virtual-machine.dc1" : {
              id              = "windows11-1"
              name            = "windows11"
              kind            = ""
              address         = "192.168.7.11"
              port            = 0
              meta            = {}
              tags            = []
              namespace       = null
              status          = "passing"
              node            = "xing-virtual-machine"
              node_id         = "22ddbd29-0454-4726-b207-82418ac5b4e3"
              node_address    = "127.0.0.1"
              node_datacenter = "dc1"
              node_tagged_addresses = {
                lan      = "127.0.0.1"
                lan_ipv4 = "127.0.0.1"
                wan      = "127.0.0.1"
                wan_ipv4 = "127.0.0.1"
              }
              node_meta = {
                consul-network-segment = ""
              }
              cts_user_defined_meta = {}
            },
            "windows11-2.xing-virtual-machine.dc1" : {
              id              = "windows11-2"
              name            = "windows11"
              kind            = ""
              address         = "192.168.7.12"
              port            = 0
              meta            = {}
              tags            = []
              namespace       = null
              status          = "passing"
              node            = "xing-virtual-machine"
              node_id         = "22ddbd29-0454-4726-b207-82418ac5b4e3"
              node_address    = "127.0.0.1"
              node_datacenter = "dc1"
              node_tagged_addresses = {
                lan      = "127.0.0.1"
                lan_ipv4 = "127.0.0.1"
                wan      = "127.0.0.1"
                wan_ipv4 = "127.0.0.1"
              }
              node_meta = {
                consul-network-segment = ""
              }
              cts_user_defined_meta = {}
            }
          }
          ```

      * **providers.tfvars:**
        * This variables file is generated with the configurations from user.
        
          Example providers.tfvars file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          fortios = {
            hostname = "<Your hostname or IP>"
            insecure = "true"
            token    = "<Your token>"
            vdom     = "<Your vdom>"
          }
          ```

      * **terraform.tfvars.tmpl:**
        * This file is generated with the configurations from user.
        
          Example terraform.tfvars.tmpl file:
          ```terraform
          # This file is generated by Consul Terraform Sync.
          #
          # The HCL blocks, arguments, variables, and values are derived from the
          # operator configuration for Sync. Any manual changes to this file
          # may not be preserved and could be overwritten by a subsequent update.
          #
          # Task: CTS-test
          # Description: Dynamic manage FortiOS Firewall address and address group by Consul_Terraform_Sync

          services = {
          {{- with $srv := service "finance_workstations" }}
            {{- $last := len $srv | subtract 1}}
            {{- range $i, $s := $srv}}
            "{{ joinStrings "." .ID .Node .Namespace .NodeDatacenter }}" : {
          {{ HCLService $s | indent 4 }}
            } {{- if (ne $i $last)}},{{end}}
            {{- end}}
          {{- end}}{{- with $beforeSrv := service "finance_workstations" }}
            {{- with $afterSrv := service "windows10" }},{{end}}
          {{- end}}
          {{- with $srv := service "windows10" }}
            {{- $last := len $srv | subtract 1}}
            {{- range $i, $s := $srv}}
            "{{ joinStrings "." .ID .Node .Namespace .NodeDatacenter }}" : {
          {{ HCLService $s | indent 4 }}
            } {{- if (ne $i $last)}},{{end}}
            {{- end}}
          {{- end}}{{- with $beforeSrv := service "windows10" }}
            {{- with $afterSrv := service "windows11" }},{{end}}
          {{- end}}
          {{- with $srv := service "windows11" }}
            {{- $last := len $srv | subtract 1}}
            {{- range $i, $s := $srv}}
            "{{ joinStrings "." .ID .Node .Namespace .NodeDatacenter }}" : {
          {{ HCLService $s | indent 4 }}
            } {{- if (ne $i $last)}},{{end}}
            {{- end}}
          {{- end}}
          }

          ```
      * **Network Infrastructure Automation (NIA) compatible modules are built to utilize the above service variables**
    6. **consul-terraform-sync** manages the entire Terraform workflow of plan, apply and destroy for all the individual workspaces corresponding to the defined "tasks" based on the updates to the services for those tasks.
    
  **In summary, consul-terraform-sync triggers a Terraform workflow (plan, apply, destroy) based on updates it detects from Consul catalog.**

