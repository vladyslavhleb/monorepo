output "ecr_endpoint_sample_1" {
  value     = data.aws_ecr_repository.data_ecr_repository_sample_1.repository_url
  sensitive = false
}

output "ecr_endpoint_sample_2" {
  value     = data.aws_ecr_repository.data_ecr_repository_sample_2.repository_url
  sensitive = false
}

