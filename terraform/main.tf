terraform {
  required_version = ">=0.12"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.54.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

variable "digitalocean_token" {
  type        = string
  description = "The DigitalOcean token to use."
  sensitive   = true
}

variable "connection_name" {
  type        = string
  description = "The name of the Wireguard connection to associate to the droplet."
}


data "digitalocean_image" "wg-tunnel" {
  name = "wireguard-tunnel-almalinux-9-x64"
}

resource "digitalocean_ssh_key" "wg-tunnel-key" {
  name       = "Wireguard Tunnel"
  public_key = file("./.ssh/id_ed25519.pub") // you want to generate this outside of Terraform.
}


resource "digitalocean_droplet" "vps" {
  image    = data.digitalocean_image.wg-tunnel.id
  name     = local.vps_name
  region   = "tor1"
  size     = "s-1vcpu-2gb"
  backups  = false
  ssh_keys = [digitalocean_ssh_key.wg-tunnel-key.fingerprint]
}

data "digitalocean_droplet" "wg-tunnel" {
  name       = local.vps_name
  depends_on = [digitalocean_droplet.vps]
}

locals {
  ip       = data.digitalocean_droplet.wg-tunnel.ipv4_address
  vps_name = replace(var.connection_name, "_", "-")
}

output "droplet_ipv4_address" {
  value = local.ip
}




data "local_file" "home-wg-conf-templated" {
  filename = "../.generated/${var.connection_name}/${var.connection_name}.conf"
}

resource "local_file" "home-wg-conf-final" {
  content  = replace(data.local_file.home-wg-conf-templated.content, "$PEER_PUBLIC_IP_ADDR", local.ip)
  filename = "/etc/wireguard/${var.connection_name}.conf"

  provisioner "local-exec" {
    command = "sudo systemctl restart wg-quick@${var.connection_name}"
  }
}