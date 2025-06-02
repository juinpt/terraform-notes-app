output "notes_profile_name" {
  value = aws_iam_instance_profile.notes_profile.name
}

outpout "opensearch_access_arn" {
  value = aws_iam_policy.opensearch_access.arn
}
