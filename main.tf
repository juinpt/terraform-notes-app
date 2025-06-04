# Creates var.instance_count EC2 instances on different subnets 
#module "web_instance" {
#  source                 = "./modules/ec2-instance"
#  instance_type          = var.instance_type
#  ami                    = var.ami
#  vpc_security_group_ids = [module.security_groups.ec2_sg_id]
#  instance_count         = var.instance_count
#  subnet_ids             = module.vpc.private_subnets_ids
#  iam_instance_profile   = module.iam.notes_profile_name
#
#  opensearch_host   = module.opensearch.opensearch_host
#  postgres_host     = module.rds-pg.postgres_host
#  postgres_port     = module.rds-pg.postgres_port
#  postgres_db       = module.rds-pg.postgres_db
#  postgres_user     = var.postgres_user
#  postgres_password = var.postgres_password
#  aws_region        = var.aws_region
#  flask_secret_key  = var.flask_secret_key
#
#}

module "ecs" {
  source            = "./modules/ecs"
  opensearch_host   = module.opensearch.opensearch_host
  postgres_host     = module.rds-pg.postgres_host
  postgres_port     = module.rds-pg.postgres_port
  postgres_db       = module.rds-pg.postgres_db
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
  aws_region        = var.aws_region
  flask_secret_key  = var.flask_secret_key

  vpc_security_group_ids = [module.security_groups.ecs_sg_id]
  subnet_ids             = module.vpc.private_subnet_ids
  alb_target_group_arn   = module.alb.alb_target_group_arn
}

#module "iam" {
#  source     = "./modules/iam"
#  aws_region = var.aws_region
#}

module "security_groups" {
  source         = "./modules/security_groups"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

module "vpc" {
  source             = "./modules/vpc"
  aws_region         = var.aws_region
  security_group_ids = [module.security_groups.ecs_sg_id]
}

module "alb" {
  source          = "./modules/alb"
  alb_sg_id       = module.security_groups.alb_sg_id
  vpc_subnet_ids  = module.vpc.private_subnet_ids
  vpc_id          = module.vpc.vpc_id
  certificate_arn = module.acm.certificate_arn
  #  web_instance_ids = module.web_instance.instance_ids
}

module "acm" {
  source         = "./modules/acm"
  fe_lb_dns_name = module.alb.fe_lb_dns_name
  fe_lb_zone_id  = module.alb.fe_lb_zone_id
  domain_name    = var.domain_name
  route53_zone   = var.route53_zone
  dns_name_alias = var.dns_name_alias
}

module "rds-pg" {
  source            = "./modules/rds-pg"
  security_group_id = module.security_groups.rds_sg_id
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
}

module "opensearch" {
  source            = "./modules/opensearch"
  ecs_task_role_arn = module.ecs.ecs_task_role_arn
}

#For GitHub Actions Workflow
terraform {
  backend "remote" {
    organization = "juinpt"
    workspaces {
      name = "terraform-notes-app"
    }
  }
}
