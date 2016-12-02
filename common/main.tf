variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "us-east-1"
}

# IAM Role
resource "aws_iam_role" "iam-role" {
  name = "iam-role"
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF
}

# Role policy
resource "aws_iam_role_policy" "iam-role-policy" {
  name = "iam-role"
  role = "${aws_iam_role.iam-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": [
      "*"
    ],
    "Effect": "Allow",
    "Resource": "*"
  }
  ]
}
EOF
}

# Instance Profile
resource "aws_iam_instance_profile" "iam-profile" {
  name = "iam-role"
  roles = ["${aws_iam_role.iam-role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}
