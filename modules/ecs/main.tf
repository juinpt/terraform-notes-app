data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

resource "aws_iam_policy" "opensearch_access" {
  name = "notes-opensearch-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "es:ESHttpGet",
        "es:ESHttpPut",
        "es:ESHttpPost"
      ],
      Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/notes-app/*"
    }]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ecs_secrets_access" {
  name        = "ecs-secrets-access"
  description = "Allows ECS tasks to retrieve secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_access_attachment" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "attach_opensearch" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.opensearch_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}


resource "aws_secretsmanager_secret" "postgres_password" {
  name = "postgres_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "postgres_password_version" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = var.postgres_password
}

resource "aws_secretsmanager_secret" "flask_secret_key" {
  name = "flask_secret_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "flask_secret_key_version" {
  secret_id     = aws_secretsmanager_secret.flask_secret_key.id
  secret_string = var.flask_secret_key
}

resource "aws_ecs_cluster" "notes-app" {
  name = "notes-app"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

}

resource "aws_ecs_task_definition" "notes-app" {
  family                   = "notes-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "notes-app"
      image     = "211584806996.dkr.ecr.ap-northeast-1.amazonaws.com/learning/notes-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ],
      environment = [
        { name = "POSTGRES_HOST", value = var.postgres_host },
        { name = "POSTGRES_PORT", value = tostring(var.postgres_port) },
        { name = "POSTGRES_DB", value = var.postgres_db },
        { name = "POSTGRES_USER", value = var.postgres_user },
        { name = "OPENSEARCH_HOST", value = var.opensearch_host },
        { name = "AWS_REGION", value = var.aws_region }
      ],
      secrets = [
        {
          name      = "POSTGRES_PASSWORD",
          valueFrom = aws_secretsmanager_secret.postgres_password.arn
        },
        {
          name      = "FLASK_SECRET_KEY",
          valueFrom = aws_secretsmanager_secret.flask_secret_key.arn
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "notes-app" {
  name            = "notes-app"
  cluster         = aws_ecs_cluster.notes-app.id
  task_definition = aws_ecs_task_definition.notes-app.arn

  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  desired_count                      = 1

  force_new_deployment = true

  network_configuration {
    security_groups  = var.vpc_security_group_ids
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "notes-app"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

