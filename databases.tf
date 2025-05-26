#resource "aws_kms_key" "notes_kms_key" {
#  description             = "KMS key for encrypting RDS and OpenSearch for Notes App"
#  enable_key_rotation     = true
#  deletion_window_in_days = 7
#}

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "notes-db"
  engine                  = "postgres"
  engine-version          = "15.13"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "notesdb"
  username                = var.postgres_user
  password                = var.postgres_password
  multi_az                = false # for saving costs, turn on for hot-standby redudancy
  backup_retention_period = 7
  backup_window           = "15:00-16:00" # 00:00-01:00 JST
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true # So a final snapshot is taken on destroy
  publicly_accessible     = true # For testing purposes

  tags = {
    Name = "notes-postgres"
  }
}

data "aws_region" "current" {

}

data "aws_caller_identity" "current" {

}

data "aws_iam_policy_document" "notes_app_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/notes-app/*"]
  }
}

resource "aws_opensearch_domain" "es" {
  domain_name    = "notes-app"
  engine_version = "OpenSearch_2.19"

  cluster_config {
    instance_type          = "t3.small.search"
    instance_count         = 2
    zone_awareness_enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  encrypt_at_rest {
    enabled = true
  }

  snapshot_options {
    automated_snapshot_start_hour = 17 # 2am JST
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = data.aws_iam_policy_document.notes_app_policy.json

  tags = {
    Name = "notes-opensearch"
  }
}
