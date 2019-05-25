variable "az" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "env" {
  type    = "string"
  default = "dev"
}

variable "image" {
  type = "string"
}

variable "vpc" {
  type = "string"
}
