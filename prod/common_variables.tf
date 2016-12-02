variable "access_key" {}
variable "secret_key" {}
variable "private_key" {}

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

variable "nat_amis" {
  type = "map"
  default = {
    us-east-1 = "ami-863b6391",
    us-east-2 = "ami-8d5a00e8",
    us-west-1 = "ami-f4e8a394",
    us-west-2 = "ami-d0c066b0",
    eu-central-1 = "ami-fd619992",
    eu-west-1 = "ami-509dd623",
    ap-northeast-1 = "ami-c50cafa4",
    ap-northeast-2 = "ami-b036e2de",
    ap-south-1 = "ami-93b5c1fc",
    ap-southeast-1 = "ami-df50f1bc",
    ap-southeast-2 = "ami-ae714dcd",
    sa-east-1 = "ami-98b824f4"
  }
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
