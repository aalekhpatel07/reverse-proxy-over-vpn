packer {
  required_plugins {
    # docker = {
    #   version = ">= 1.0.8"
    #   source  = "github.com/hashicorp/docker"
    # }
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
    default = env("DIGITALOCEAN_API_TOKEN")

    validation {
        condition = length(var.digitalocean_api_token) > 0
        error_message = <<EOF
The digitalocean_api_token var is not set: make sure to set the DIGITALOCEAN_API_TOKEN env var.
EOF
    }
}

variable "digitalocean_region" {
    default = env("DIGITALOCEAN_REGION")

    validation {
        condition = length(var.digitalocean_region) > 0
        error_message = <<EOF
The digitalocean_region var is not set: make sure to set the DIGITALOCEAN_REGION env var.
EOF
    }
}



source "digitalocean" "tunnel-base" {
  api_token     = var.digitalocean_api_token
  ssh_username  = "root"
  image         = "almalinux-9-x64"
  size          = "s-1vcpu-2gb"
  region        = var.digitalocean_region
  snapshot_name = "wireguard-tunnel-almalinux-9-x64"
  snapshot_tags = ["wireguard-tunnel", "almalinux-9"]
}

build {
  sources = [
    "source.digitalocean.tunnel-base"
  ]

  provisioner "ansible" {
    playbook_file = "./packer/ansible/playbooks/playbook.yml"
  }
}