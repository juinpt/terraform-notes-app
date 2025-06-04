variable "aws_region" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}
