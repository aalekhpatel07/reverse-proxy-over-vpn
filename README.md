# Reverse Proxy over a VPN (i.e. a Wireguard Tunnel)

For when you have a beefy workstation that you would like to run some services on, and would like to expose some of those services to the rest of the internet but hidden behind a VPS.

## Usage

1. Create an account on [DigitalOcean](https://cloud.digitalocean.com) and [set up a personal access token](https://cloud.digitalocean.com/account/api/tokens) that will be used to create and provision VPSes.
  
Copy `.env.example` to `.env`, and save the token in it:
```sh
# in .env
TF_VAR_digitalocean_token=<api-token-goes-here>
```

2. Ensure you have [Packer](https://developer.hashicorp.com/packer) and [Terraform](https://developer.hashicorp.com/terraform) installed on your host machine. We'll use Packer to build the image that your VPS will run (including wireguard, and nftables both), and Terraform to deploy that image to a DigitalOcean droplet that has a publically accessible IPv4 address.

3. Create an SSH Key pair under `./terraform/.ssh/id_ed25519`. You'll be able to use this key to ssh into the VPS once its deployed (when needed):

```sh
mkdir -p ./terraform/.ssh
ssh-keygen -t ed25519 -f ./terraform/.ssh/id_ed25519 -q -N ""
```

4. Make any changes, if necessary, to the variables in the [Makefile](./Makefile):

- `HOME_ADDR`: This will be the IP address assigned to the "home" end of the Wireguard tunnel.
- `PEER_ADDR`: This will be the IP address assigned to the "remote" end of the Wireguard tunnel.
- `TUNNEL_NAME`: A unique name for this Wireguard Tunnel.
- `VPS_SHOULD_PORT_FORWARD_TO`: The port (on the "home" end) that the VPS should redirect all TCP traffic to.

5. Run `make all` and follow any instructions on the Packer and Terraform process. Take a note of `droplet_ipv4_address` at the end of the process. That is your VPS's publically accessible IP address.
   
6. If everything went okay, start a dummy nginx container to test that the packets are shuttled nicely over the Wireguard tunnel:

```sh
docker run --rm --name nginx -d -p 8005:80 nginx
```

7. Visit `http://<droplet_ipv4_address>/` and verify that NGINX is accessible.