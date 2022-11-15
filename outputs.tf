# Output value definitions

output "ecr_repository_name" {
  description = "Name of ECR repository."
  value = aws_ecr_repository.plane_delay.repository_url
}

output "ecs_cluster_name" {
  description = "Name of ECS cluster."
  value = aws_ecs_cluster.plane_delay_cluster.name
}

output "ecs_service_name" {
  description = "Name of ECS service."
  value = aws_ecs_service.plane_delay_service.name
}
