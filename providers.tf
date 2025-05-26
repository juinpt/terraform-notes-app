provider "aws" {
  # This is only used for with my AWS CLI config
  #  profile = "default"
  #  region  = "ap-northeast-1"
  region = var.aws_region
}
