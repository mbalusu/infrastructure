variable "asgs" {
  type = "map"
  default = {
    tomcat.min = 0,
    tomcat.max = 2,
    tomcat.desired = 2,
    rabbitmq.min = 0,
    rabbitmq.max = 2,
    rabbitmq.desired = 2
  }
}

variable "instance_type" {
  type = "map"
  default = {
    tomcat = "m3.medium",
    rabbitmq = "m3.medium"
    mongo-master = "m3.medium"
    mongo-slave = "m3.medium"
    mongo-arbiter = "m3.medium"
    vpn = "t2.large"
    nat = "t2.large"
  }
}

variable "root_vol_size" {
  type = "map"
  default = {
    tomcat = "50",
    rabbitmq = "50"
    mongo-master = "50"
    mongo-slave = "50"
    mongo-arbiter = "50"
    vpn = "20"
    nat = "20"
  }
}

variable "ebs_vol_size" {
  type = "map"
  default = {
    mongo-master = "200"
    mongo-slave = "200"
    mongo-arbiter = "200"
  }
}

variable "tomcat_lb_name" {
  default = "web"
}
variable "tomcat_fxoffice_lb_name" {
  default = "fxoffice"
}
variable "rabbitmq_lb_name" {
  default = "amqp"
}

variable "mongo_admin_user" {
  default = "mongo_admin"
}

variable "mongo_admin_password" {
  default = "p@ssw0rd"
}
