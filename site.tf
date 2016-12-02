module "common" {
  source = "./common"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

module "prod_vpc" {
  source = "./prod"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  key_name = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  environment = "Production"
  aws_region = "us-west-1"
  infra_regions = "us-west-1,us-west-2"
  private_key = "${var.private_key}"
  iam_instance_profile = "${module.common.iam_instance_profile}"
  openvpn_server_ip_block = "172.16.1.0"
  openvpn_server_netmask = "255.255.255.0"
  openvpn_route_ip_block = "10.180.0.0"
  openvpn_route_netmask = "255.255.0.0"
  remote_ip = "192.168.1.0"
}

module "dr_vpc" {
  source = "./dr"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  key_name = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  environment = "DR"
  aws_region = "us-west-2"
  infra_regions = "us-west-1,us-west-2"
  private_key = "${var.private_key}"
  iam_instance_profile = "${module.common.iam_instance_profile}"
  openvpn_server_ip_block = "172.16.2.0"
  openvpn_server_netmask = "255.255.255.0"
  openvpn_route_ip_block = "10.181.0.0"
  openvpn_route_netmask = "255.255.0.0"
  remote_ip = "192.168.2.0"
}
