data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

resource "aws_iam_role" "notes_ec2_role" {
  name = "notes-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
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

resource "aws_iam_role_policy_attachment" "opensearch_access" {
  role       = aws_iam_role.notes_ec2_role.name
  policy_arn = aws_iam_policy.opensearch_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.notes_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.notes_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "notes_profile" {
  name = "notes-instance-profile"
  role = aws_iam_role.notes_ec2_role.name
}
