output "ecs_cluster_id" {
  value = aws_ecs_cluster.node_app.id
}

output "ecs_service_name" {
  value = aws_ecs_service.node_app.name
}

