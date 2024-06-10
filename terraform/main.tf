provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "node_app_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "node-app-vpc"
  }
}

resource "aws_internet_gateway" "node_app_igw" {
  vpc_id = aws_vpc.node_app_vpc.id

  tags = {
    Name = "node-app-igw"
  }
}

resource "aws_route_table" "node_app_route_table" {
  vpc_id = aws_vpc.node_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.node_app_igw.id
  }

  tags = {
    Name = "node-app-route-table"
  }
}

resource "aws_subnet" "node_app_subnet" {
  count             = 2
  vpc_id            = aws_vpc.node_app_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "node-app-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "node_app_route_table_assoc" {
  count          = 2
  subnet_id      = aws_subnet.node_app_subnet[count.index].id
  route_table_id = aws_route_table.node_app_route_table.id
}

resource "aws_security_group" "node_app_sg" {
  vpc_id = aws_vpc.node_app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "node-app-sg"
  }
}

resource "aws_lb" "node_app_lb" {
  name               = "node-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.node_app_sg.id]
  subnets            = aws_subnet.node_app_subnet[*].id

  tags = {
    Name = "node-app-alb"
  }
}

resource "aws_lb_target_group" "node_app_tg" {
  name        = "node-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.node_app_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "node-app-tg"
  }
}

resource "aws_lb_listener" "node_app_listener" {
  load_balancer_arn = aws_lb.node_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_app_tg.arn
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name   = "ecsTaskExecutionPolicy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "node_app_log_group" {
  name              = "/ecs/node-app"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "node_app" {
  name = "node-app-cluster"
}

resource "aws_ecs_task_definition" "node_app" {
  family                   = "node-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "node-app"
      image     = "uday27/nodeapp:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/node-app"
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "node_app" {
  name            = "node-app-service"
  cluster         = aws_ecs_cluster.node_app.id
  task_definition = aws_ecs_task_definition.node_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.node_app_subnet[*].id
    security_groups = [aws_security_group.node_app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.node_app_tg.arn
    container_name   = "node-app"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.node_app_listener
  ]
}

