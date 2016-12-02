provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Create VPC
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.vpc_name}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default.id}"
}

# Create Public Subnet in AZ-1
resource "aws_subnet" "az1-public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.public_subnets, "az1.cidr")}"
  availability_zone = "${lookup(var.public_subnets, "az1.availability_zone")}"

  tags {
    Name = "Public Subnet 1"
  }
}

# Create Public Subnet in AZ-2
resource "aws_subnet" "az2-public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.public_subnets, "az2.cidr")}"
  availability_zone = "${lookup(var.public_subnets, "az2.availability_zone")}"

  tags {
    Name = "Public Subnet 2"
  }
}

# Create Private Subnet in AZ-1
resource "aws_subnet" "az1-private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.private_subnets, "az1.cidr")}"
  availability_zone = "${lookup(var.private_subnets, "az1.availability_zone")}"

  tags {
    Name = "Private Subnet 1"
  }
}

# Create Private Subnet in AZ-2
resource "aws_subnet" "az2-private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.private_subnets, "az2.cidr")}"
  availability_zone = "${lookup(var.private_subnets, "az2.availability_zone")}"

  tags {
    Name = "Private Subnet 2"
  }
}

# Create Private Subnet in AZ-3
resource "aws_subnet" "az3-private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${lookup(var.private_subnets, "az3.cidr")}"
  availability_zone = "${lookup(var.private_subnets, "az3.availability_zone")}"

  tags {
    Name = "Private Subnet 3"
  }
}
# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "Public Subnets"
  }
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }

  route {
    cidr_block = "${var.peer_vpc_cidr}"
    instance_id = "${aws_instance.vpn.id}"
  }

  tags {
    Name = "Private Subnets"
  }
}

# Create route table for Peer VPC
resource "aws_route_table" "peer" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "${var.peer_vpc_cidr}"
    instance_id = "${aws_instance.vpn.id}"
  }

  route {
    cidr_block = "${var.peer_vpc_cidr}"
    instance_id = "${aws_instance.vpn.id}"
  }

  tags {
    Name = "Peer VPC Subnets"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "az1-public" {
  subnet_id = "${aws_subnet.az1-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route_table_association" "az2-public" {
  subnet_id = "${aws_subnet.az2-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "az1-private" {
  subnet_id = "${aws_subnet.az1-private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "az2-private" {
  subnet_id = "${aws_subnet.az2-private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "az3-private" {
  subnet_id = "${aws_subnet.az3-private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

# Security group for NAT instance
resource "aws_security_group" "nat" {
  name = "nat"
  description = "Allow traffic to pass from private subnet to Internet"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    from_port = 22
    to_port = 22
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
    Name = "NATSG"
  }
}

resource "aws_key_pair" "key-pair" {
  key_name = "${var.key_name}"
  public_key = "${file("./id_rsa.pub")}"
}

resource "aws_instance" "nat" {
  ami = "${lookup(var.nat_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_type, "nat")}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${aws_subnet.az1-public.id}"
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    Name = "NATBox"
  }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}
