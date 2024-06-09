provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

# Create a new VPC
resource "aws_vpc" "nodeapp_vpc" {
  cidr_block = "10.0.0.0/16"  # Update with your desired CIDR block for the VPC
}

# Create a new public subnet within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.nodeapp_vpc.id
  cidr_block        = "10.0.1.0/24"  # Update with your desired CIDR block for the subnet
  availability_zone = "us-east-1a"   # Update with your desired availability zone
}

# Create a new security group allowing traffic on port 3000
resource "aws_security_group" "nodeapp_security_group" {
  vpc_id = aws_vpc.nodeapp_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "nodeapp_cluster" {
  name = "nodeapp-cluster"  # Update with your desired ECS cluster name
}

# ECS Task Definition
resource "aws_ecs_task_definition" "nodeapp_task_definition" {
  family                   = "nodeapp-task"  # Update with your desired task definition family name
  cpu                      = "256"          # Update with your desired CPU units
  memory                   = "512"          # Update with your desired memory in MiB
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "nodeapp-container"                          # Update with your desired container name
      image     = "uday27/nodeapp:latest" # Update with your Docker Hub username, image name, and tag
      cpu       = 256                                         # Update with your desired CPU units for the container
      memory    = 512                                         # Update with your desired memory in MiB for the container
      essential = true
      portMappings = [
        {
          containerPort = 3000               # Update with the port your Node.js app is listening on
          hostPort      = 3000               # Update if you want to map a different host port
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "nodeapp_service" {
  name            = "nodeapp-service"  # Update with your desired service name
  cluster         = aws_ecs_cluster.nodeapp_cluster.id
  task_definition = aws_ecs_task_definition.nodeapp_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.nodeapp_security_group.id]
    assign_public_ip = true
  }
}

