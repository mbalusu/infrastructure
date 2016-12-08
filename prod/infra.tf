# Security group for Loadbalancer for Web Cluster
resource "aws_security_group" "web" {
  name = "web"
  description = "Allow access to HTTP and HTTPS on loadbalancer"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "WEBSG"
  }
}
resource "aws_security_group" "fxoffice" {
  name = "fxoffice"
  description = "Allow access to HTTP and HTTPS on loadbalancer"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "OFFICESG"
  }
}
# Security group to allow access to all services on private network inside of VPC.
resource "aws_security_group" "internal" {
  name = "internal"
  description = "Allow access internally within VPC"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}","${var.peer_vpc_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "INTERNALSG"
  }
}

# Security group for openvpn instance.
resource "aws_security_group" "vpn" {
  name = "vpn"
  description = "Allow access via VPN tunnel"

  ingress {
    from_port = 1194
    to_port = 1194
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 1194
    to_port = 1194
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "VPNSG"
  }
}

resource "template_file" "userdata_vpn" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    environment = "${var.environment}"
    service = "openvpn"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,openvpn"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "aws_instance" "vpn" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "vpn")}"
  security_groups = ["${aws_security_group.vpn.id}","${aws_security_group.internal.id}"]
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  subnet_id = "${aws_subnet.az1-public.id}"
  user_data = "${template_file.userdata_vpn.rendered}"
  associate_public_ip_address = true
  source_dest_check = false
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "vpn")}"
  }
}

resource "aws_alb" "tomcat-lb" {
  name = "tomcat-lb"
  internal = false
  subnets = ["${aws_subnet.az1-public.id}","${aws_subnet.az2-public.id}"]
  security_groups = ["${aws_security_group.web.id}"]
  enable_deletion_protection = false
  tags {
    Environment = "production"
  }
}
resource "aws_alb" "tomcat-fxoffice-lb" {
  name = "tomcat-lb"
  internal = false
  subnets = ["${aws_subnet.az1-public.id}","${aws_subnet.az2-public.id}"]
  security_groups = ["${aws_security_group.fxoffice.id}"]
  enable_deletion_protection = false
  tags {
    Environment = "production"
  }
}
resource "aws_alb_listener" "tomcat-lb-li" {
  load_balancer_arn = "${aws_alb.tomcat-lb.arn}"
  port = "80"
  protocol = "HTTP"
  default_action {
    target_group_arn = "${aws_alb_target_group.tomcat-lb-tg.arn}"
    type = "forward"
  }
}
resource "aws_alb_listener" "tomcat-fxoffice-lb-li" {
  load_balancer_arn = "${aws_alb.tomcat-fxoffice-lb.arn}"
  port = "80"
  protocol = "HTTP"
  default_action {
    target_group_arn = "${aws_alb_target_group.tomcat-fxoffice-lb-tg.arn}"
    type = "forward"
  }
}
resource "aws_alb_target_group" "tomcat-lb-tg" {
  name = "tomcat-lb-tg"
  port = "8080"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.default.id}"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
  }
}
resource "aws_alb_target_group" "tomcat-fxoffice-lb-tg" {
  name = "tomcat-fxoffice-lb-tg"
  port = "8080"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.default.id}"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
  }
}
resource "aws_route53_record" "tomcat-lb" {
  zone_id = "${aws_route53_zone.public_zone.zone_id}"
  name = "${var.tomcat_lb_name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_alb.tomcat-lb.dns_name}"]
}
resource "aws_route53_record" "tomcat-fxoffice-lb" {
  zone_id = "${aws_route53_zone.public_zone.zone_id}"
  name = "${var.tomcat_fxoffice_lb_name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_alb.tomcat-fxoffice-lb.dns_name}"]
}
resource "template_file" "userdata_tomcat" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    tag_name = "Web"
    environment = "${var.environment}"
    service = "tomcat"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,sdx_tomcat,sdx_tomcat::tomcat_fxweb"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "aws_autoscaling_group" "tomcat-asg" {
  name = "tomcat-asg"
  vpc_zone_identifier = ["${aws_subnet.az1-private.id}","${aws_subnet.az2-private.id}"]
  max_size = "${lookup(var.asgs,"tomcat.max")}"
  min_size = "${lookup(var.asgs,"tomcat.min")}"
  desired_capacity = "${lookup(var.asgs,"tomcat.desired")}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.tomcat-lc.name}"
  target_group_arns = ["${aws_alb_target_group.tomcat-lb-tg.arn}"]
  tag {
    key = "ASG-Name"
    value = "tomcat-asg"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_group" "tomcat-fxoffice-asg" {
  name = "tomcat-asg"
  vpc_zone_identifier = ["${aws_subnet.az1-private.id}","${aws_subnet.az2-private.id}"]
  max_size = "${lookup(var.asgs,"tomcat.max")}"
  min_size = "${lookup(var.asgs,"tomcat.min")}"
  desired_capacity = "${lookup(var.asgs,"tomcat.desired")}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.tomcat-fxoffice-lc.name}"
  target_group_arns = ["${aws_alb_target_group.tomcat-fxoffice-lb-tg.arn}"]
  tag {
    key = "ASG-Name"
    value = "tomcat-fxoffice-asg"
    propagate_at_launch = true
  }
}
resource "aws_launch_configuration" "tomcat-lc" {
  name = "tomcat-lc"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "tomcat")}"
  security_groups = ["${aws_security_group.internal.id}","${aws_security_group.web.id}"]
  user_data = "${template_file.userdata_tomcat.rendered}"
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "tomcat")}"
  }
}
resource "aws_launch_configuration" "tomcat-fxoffice-lc" {
  name = "tomcat-lc"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "tomcat")}"
  security_groups = ["${aws_security_group.internal.id}","${aws_security_group.fxoffice.id}"]
  user_data = "${template_file.userdata_tomcat.rendered}"
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "tomcat")}"
  }
}
resource "aws_elb" "rabbitmq-lb" {
  name = "rabbitmq-lb"

  internal = true
  subnets = ["${aws_subnet.az1-private.id}","${aws_subnet.az2-private.id}"]
  security_groups = ["${aws_security_group.internal.id}"]
  listener {
    instance_port = 5672
    instance_protocol = "tcp"
    lb_port = 5672
    lb_protocol = "tcp"
  }
  listener {
    instance_port = 15672
    instance_protocol = "http"
    lb_port = 15672
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:5672"
    interval = 30
  }
  cross_zone_load_balancing = true
  tags {
    Name = "rabbitmq-lb"
  }
}

resource "aws_route53_record" "rabbitmq-lb" {
  zone_id = "${aws_route53_zone.private_zone.zone_id}"
  name = "${var.rabbitmq_lb_name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_elb.rabbitmq-lb.dns_name}"]
}

resource "template_file" "userdata_rabbitmq" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    environment = "${var.environment}"
    service = "rabbitmq"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,rabbitmq"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "aws_autoscaling_group" "rabbitmq-asg" {
  name = "rabbitmq-asg"
  vpc_zone_identifier = ["${aws_subnet.az1-private.id}","${aws_subnet.az2-private.id}"]
  max_size = "${lookup(var.asgs,"rabbitmq.max")}"
  min_size = "${lookup(var.asgs,"rabbitmq.min")}"
  desired_capacity = "${lookup(var.asgs,"rabbitmq.desired")}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.rabbitmq-lc.name}"
  load_balancers = ["${aws_elb.rabbitmq-lb.name}"]
  tag {
    key = "ASG-Name"
    value = "rabbitmq-asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "rabbitmq-lc" {
  name = "rabbitmq-lc"
  image_id = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "rabbitmq")}"

  security_groups = ["${aws_security_group.internal.id}"]
  user_data = "${template_file.userdata_rabbitmq.rendered}"
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "rabbitmq")}"
  }
}

resource "template_file" "userdata_mongo_master" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    environment = "${var.environment}"
    service = "mongo-master"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,mongo"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "template_file" "userdata_mongo_slave" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    environment = "${var.environment}"
    service = "mongo-slave"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,mongo"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "template_file" "userdata_mongo_arbiter" {
  template = "${file("scripts/userdata.tpl")}"
  vars = {
    aws_region = "${var.aws_region}"
    environment = "${var.environment}"
    service = "mongo-arbiter"
    regions = "${var.infra_regions}"
    private_key = "${var.private_key}"
    run_list = "base,mongo"
    openvpn_server_ip_block = "${var.openvpn_server_ip_block}"
    openvpn_server_netmask = "${var.openvpn_server_netmask}"
    openvpn_route_ip_block = "${var.openvpn_route_ip_block}"
    openvpn_route_netmask = "${var.openvpn_route_netmask}"
    remote_ip = "${var.remote_ip}"
    mongo_admin_user = "${var.mongo_admin_user}"
    mongo_admin_password = "${var.mongo_admin_password}"
  }
}

resource "aws_instance" "mongo-master" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "mongo-master")}"
  security_groups = ["${aws_security_group.internal.id}"]
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  subnet_id = "${aws_subnet.az1-private.id}"
  user_data = "${template_file.userdata_mongo_master.rendered}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "mongo-master")}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = "${lookup(var.ebs_vol_size, "mongo-master")}"
  }
}

resource "aws_instance" "mongo-slave" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "mongo-slave")}"
  security_groups = ["${aws_security_group.internal.id}"]
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  subnet_id = "${aws_subnet.az2-private.id}"
  user_data = "${template_file.userdata_mongo_slave.rendered}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "mongo-slave")}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = "${lookup(var.ebs_vol_size, "mongo-slave")}"
  }
}

resource "aws_instance" "mongo-arbiter" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "mongo-arbiter")}"
  security_groups = ["${aws_security_group.internal.id}"]
  key_name = "${var.key_name}"
  iam_instance_profile = "${var.iam_instance_profile}"
  subnet_id = "${aws_subnet.az3-private.id}"
  user_data = "${template_file.userdata_mongo_arbiter.rendered}"
  root_block_device {
    volume_size = "${lookup(var.root_vol_size, "mongo-arbiter")}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = "${lookup(var.ebs_vol_size, "mongo-arbiter")}"
  }
}
