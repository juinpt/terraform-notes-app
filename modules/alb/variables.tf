variable "alb_sg_id" {
  type = string
}

variable "vpc_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

#variable "web_instance_ids" {
#  type = list(string)
#}
