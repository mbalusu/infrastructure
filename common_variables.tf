variable "access_key" {}
variable "secret_key" {}
variable "private_key" {}

variable "infra_regions" {
  default = "us-east-1,us-east-2"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "amis" {
  type = "map"
  default = {
    us-east-1 = "ami-38de8d2f",
    us-east-2 = "ami-58045e3d",
    us-west-1 = "ami-a4175cc4",
    us-west-2 = "ami-cbd276ab",
    eu-central-1 = "ami-b87881d7",
    eu-west-1 = "ami-3e713f4d",
    ap-northeast-1 = "ami-4764c226",
    ap-northeast-2 = "ami-3de23653",
    ap-south-1 = "ami-a65420c9",
    ap-southeast-1 = "ami-c13690a2",
    ap-southeast-2 = "ami-b6370ad5",
    sa-east-1 = "ami-7238a51e"
  }
}

variable "instance_type" {
  default = "t2.micro"
}

variable "public_key_path" {
  description = <<EOF
Path to SSH public key to be used for authentication.
Example: ~/.ssh/mykey.pub
EOF
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "Test"
}
