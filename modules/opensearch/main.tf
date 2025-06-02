data "aws_region" "current" {

}

data "aws_caller_identity" "current" {

}

data "aws_iam_policy_document" "notes_app_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.ecs_task_role_arn]
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
