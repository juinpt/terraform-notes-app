variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
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

variable "opensearch_host" {
  type = string
}

variable "alb_target_group_arn" {
  type = string
}
