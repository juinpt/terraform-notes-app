variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS Region"
}

variable "ami" {
  type        = string
  description = "The AMI for the EC2 instances; must be ubuntu"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "postgres_user" {
  type    = string
  default = "postgres"
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "flask_secret_key" {
  type      = string
  sensitive = true
}

variable "domain_name" {
  type    = string
  default = "my-aws-app.afonso.jp"
}

