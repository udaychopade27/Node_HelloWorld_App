output "ecs_cluster_id" {
  value = aws_ecs_cluster.nodeapp.id
}

output "ecs_service_name" {
  value = aws_ecs_service.nodeapp.name
}

