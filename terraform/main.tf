provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "nodeapp_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "nodeapp-vpc"
  }
}

resource "aws_subnet" "nodeapp_subnet" {
  count             = 2
  vpc_id            = aws_vpc.nodeapp_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "nodeapp-subnet-${count.index}"
  }
}

data "aws_availability_zones" "available" {}

# Create Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.nodeapp_vpc.id

  tags = {
    Name = "example-igw"
  }
}

# Update Route Table to Route Traffic to Internet Gateway
resource "aws_route" "example" {
  route_table_id         = aws_route_table.example.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example.id
}

# Example Route Table Association
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.nodeapp_subnet[0].id
  route_table_id = aws_route_table.example.id
}

# Create Route Table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.nodeapp_vpc.id

  tags = {
    Name = "example-route-table"
  }
}


resource "aws_security_group" "nodeapp_sg" {
  vpc_id = aws_vpc.nodeapp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "nodeapp-sg"
  }
}




resource "aws_lb" "nodeapp_lb" {
  name               = "nodeapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nodeapp_sg.id]
  subnets            = aws_subnet.nodeapp_subnet[*].id

  tags = {
    Name = "nodeapp-alb"
  }
}

resource "aws_lb_target_group" "nodeapp_tg" {
  name     = "nodeapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nodeapp_vpc.id

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
    Name = "nodeapp-tg"
  }
}

resource "aws_lb_listener" "nodeapp_listener" {
  load_balancer_arn = aws_lb.nodeapp_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nodeapp_tg.arn
  }
}

resource "aws_ecs_cluster" "nodeapp" {
  name = "nodeapp-cluster"
}

resource "aws_ecs_task_definition" "nodeapp" {
  family                   = "nodeapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "nodeapp"
      image     = "uday27/nodeapp:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "nodeapp" {
  name            = "nodeapp-service"
  cluster         = aws_ecs_cluster.nodeapp.id
  task_definition = aws_ecs_task_definition.nodeapp.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.nodeapp_subnet[*].id
    security_groups = [aws_security_group.nodeapp_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nodeapp_tg.arn
    container_name   = "nodeapp"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.nodeapp_listener
  ]
}

