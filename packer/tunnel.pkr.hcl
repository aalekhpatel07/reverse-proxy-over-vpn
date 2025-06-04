packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }

  }
}

variable "digitalocean_api_token" {
  default = env("TF_VAR_digitalocean_token")

  validation {
    condition     = length(var.digitalocean_api_token) > 0
    error_message = <<EOF
The TF_VAR_digitalocean_token var is not set: make sure to set the TF_VAR_digitalocean_token env var.
EOF
  }
}

variable "digitalocean_region" {
  default = env("TF_VAR_DIGITALOCEAN_REGION")

  validation {
    condition     = length(var.digitalocean_region) > 0
    error_message = <<EOF
The digitalocean_region var is not set: make sure to set the DIGITALOCEAN_REGION env var.
EOF
  }
}

# - name: home_addr
#   prompt: "What is the IP address of the host (over this Wireguard tunnel)? (Default: 10.10.10.1)"
#   default: "10.10.10.1"
#   private: false
# - name: home_port
#   prompt: "What is the port for the host that will host a meaningful http gateway? (Default: 80)"
#   default: "80"
#   private: false
# - name: peer_interface_ip_addr
#   prompt: "What is the IP address of the peer (over this Wireguard tunnel)? (Default: 10.10.10.2)"
#   default: "10.10.10.2"
#   private: false
# - name: connection_name
#   prompt: "Enter a human-friendly name for this Wireguard tunnel. (Default: wg_example)"
#   default: "wg_example"

variable "wg_home_addr" {
  type = string
  validation {
    condition     = length(var.wg_home_addr) > 0
    error_message = <<EOF
The wg_home_addr var is not set. 
This value is an IP address (not already in use) that will be assigned to the "home"-end of the Wireguard tunnel. 
(Try using "10.10.10.1" in case its available).
EOF
  }
}

variable "wg_home_port" {
  type = string
  validation {
    condition     = length(var.wg_home_port) > 0
    error_message = <<EOF
The wg_home_port var is not set. 
This value is the port that the "home"-side of this tunnel would 
eventually have a reverse proxy (i.e. Nginx, Caddy, Traefik, etc) on.
EOF
  }
}

variable "wg_peer_interface_ip_addr" {
  type = string

  validation {
    condition     = length(var.wg_peer_interface_ip_addr) > 0
    error_message = <<EOF
The wg_peer_interface_ip_addr var is not set. 
This value is the IP address that will be assigned to the "peer"-end of the Wireguard tunnel.
Note: Any reasonably "internal"-ish IP value works here tbh, since that peer is unlikely to have that IP used elsewhere.
EOF
  }
}

variable "wg_connection_name" {
  type = string

  validation {
    condition     = length(var.wg_connection_name) > 0
    error_message = <<EOF
The wg_connection_name var is not set.
This value is a unique identifier for this Wireguard tunnel on the "home"-side, since technically
you can have multiple tunnels on the "home"-side.
EOF
  }
}

source "digitalocean" "tunnel-base" {
  api_token     = var.digitalocean_api_token
  ssh_username  = "root"
  image         = "almalinux-9-x64"
  size          = "s-1vcpu-2gb"
  region        = var.digitalocean_region
  snapshot_name = var.wg_connection_name
  snapshot_tags = ["wireguard-tunnel", "almalinux-9"]
}

build {
  sources = [
    "source.digitalocean.tunnel-base"
  ]

  provisioner "ansible" {
    playbook_file = "./packer/ansible/playbooks/playbook.yml"
    extra_arguments = [
      "--scp-extra-args", "'-O'",
      "--extra-vars", "home_addr=${var.wg_home_addr}",
      "--extra-vars", "home_port=${var.wg_home_port}",
      "--extra-vars", "peer_interface_ip_addr=${var.wg_peer_interface_ip_addr}",
      "--extra-vars", "connection_name=${var.wg_connection_name}",
    ]
  }
}
