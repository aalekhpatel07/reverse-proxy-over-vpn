include .env

HOME_ADDR ?= 10.10.10.1
PEER_ADDR ?= 10.10.10.2
TUNNEL_NAME ?= wg_example_vps
VPS_SHOULD_FORWARD_TO_PORT ?= 8000

packer-init:
	packer init \
		packer/tunnel.pkr.hcl

packer-build:
	packer build \
		-var "wg_home_addr=$(HOME_ADDR)" \
		-var "wg_home_port=$(VPS_SHOULD_FORWARD_TO_PORT)" \
		-var "wg_connection_name=$(TUNNEL_NAME)" \
		-var "wg_peer_interface_ip_addr=$(PEER_ADDR)" \
		packer/tunnel.pkr.hcl

tf-init:
	terraform -chdir=terraform/ init

tf-apply:
	terraform -chdir=terraform/ \
        	apply \
        	-auto-approve \
        	-var connection_name=$(TUNNEL_NAME)

vps-image: packer-init packer-build
deploy-vps: tf-init tf-apply

all: vps-image deploy-vps
