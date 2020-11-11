variable "profile" {
  default = "terraform"
}

variable "region" {
  default = "us-east-1"
}

variable "instance" {
  default = "t2.micro"
}

variable "instance_count" {
  default = "1"
}

variable "public_key" {
  default = "~/.ssh/my_keypair1.pub"
}

variable "private_key" {
  default = "~/.ssh/my_keypair1.pem"
}

variable "ansible_user" {
  default = "centos"
}

variable "ami" {
  default = "ami-056940cb2a7bb6d71"
}
