variable "asgs" {
  type = "map"
  default = {
    tomcat.min = 0,
    tomcat.max = 2,
    tomcat.desired = 1,
    rabbitmq.min = 0,
    rabbitmq.max = 2,
    rabbitmq.desired = 1
  }
}

variable "instance_type" {
  type = "map"
  default = {
    tomcat = "t2.large",
    rabbitmq = "t2.large"
    mongo-master = "t2.large"
    mongo-slave = "t2.large"
    mongo-arbiter = "t2.large"
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

variable "rabbitmq_lb_name" {
  default = "amqp"
}

variable "mongo_admin_user" {
  default = "mongo_admin"
}

variable "mongo_admin_password" {
  default = "p@ssw0rd"
}
