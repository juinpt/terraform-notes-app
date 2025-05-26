# Creates var.instance_count EC2 instances on different subnets 
module "web_instance" {
  source                 = "./modules/ec2-instance"
  instance_type          = var.instance_type
  ami                    = var.ami
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  instance_count         = var.instance_count
  subnet_ids             = data.aws_subnets.default_vpc_subnets.ids
  opensearch_host        = aws_opensearch_domain.es.endpoint
  postgres_host          = aws_db_instance.postgres.address
  postgres_port          = aws_db_instance.postgres.port
  postgres_db            = aws_db_instance.postgres.db_name
  postgres_user          = var.postgres_user
  postgres_password      = var.postgres_password
  aws_region             = var.aws_region
  flask_secret_key       = var.flask_secret_key
}

# Get all subnets ids in the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "front_end" {
  name               = "my-app-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default_vpc_subnets.ids
}


resource "aws_lb_target_group" "app" {
  name     = "my-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 8080
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "notes-app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn
  alpn_policy       = "HTTP2Preferred"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count            = length(module.web_instance.instance_ids)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.web_instance.instance_ids[count.index]
  port             = 8080
}


resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
