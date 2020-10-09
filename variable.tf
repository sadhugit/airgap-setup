
variable "availabilityZone" {
     default = "ap-south-1"
}

variable "access_key" {
     default = "<PUT IN YOUR AWS ACCESS KEY>"
}
variable "secret_key" {
     default = "<PUT IN YOUR AWS ACCESS KEY>"
}
variable "vpcCIDblock"{
    type = string
    default = "10.0.0.0/16"
}
variable "public_subnet"{
    default = "10.0.4.0/24"

}
variable "private_subnet"{
    default = "10.0.3.0/24"

}
variable "bastion_host"{
    default = ""
}
variable "no_of_privatevms"{
    default = "1"
}
variable "node_username"{
    type = string
    default = "ubuntu"
}
variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "airgap-setup"
}

variable "instance_type"{
    type = string
    description = " ec2 instance type"
    default = "t3.micro"
}
variable "owner_id"{
    type = list(string)
    default=["092310109345"]
}