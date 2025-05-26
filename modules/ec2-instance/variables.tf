variable "ami" {
  type        = string
  description = "AMI ID to use for the instances"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "name_prefix" {
  type    = string
  default = "ec2"
}

variable "postgres_host" {
  type = string
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "postgres_db" {
  type    = string
  default = "postgres"
}

variable "postgres_user" {
  type    = string
  default = "postgres"
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type = string
}

variable "flask_secret_key" {
  type      = string
  sensitive = true
}

