# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}


# IAM – Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_ssm_access" {
  name = "ecs-ssm-access"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = "arn:aws:ssm:ap-south-1:${var.account_id}:parameter/curd-app/backend/*"
      },
      {
        # Needed to decrypt SecureString parameters
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}
# Security Group – ECS Tasks (only ALB can reach them)
resource "aws_security_group" "ecs" {
  name        = "ecs-sg-${var.cluster_name}"
  description = "Allow traffic only from ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Frontend port from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Backend port from ALB"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecs-sg-${var.cluster_name}" }
}

# Security Group – ALB (public-facing)
resource "aws_security_group" "alb" {
  name        = "alb-sg-${var.cluster_name}"
  description = "Allow HTTP traffic to ALB on ports 80 (frontend) and 3001 (backend)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Frontend HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend API"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg-${var.cluster_name}" }
}


# Application Load Balancer
resource "aws_lb" "main" {
  name               = "alb-${var.cluster_name}"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  tags = { Name = "alb-${var.cluster_name}" }
}


# ALB Listeners
# Port 80 → Frontend
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Port 3001 → Backend
resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}


# Target Groups
resource "aws_lb_target_group" "backend" {
  name        = "backend-tg-${var.cluster_name}"
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "backend-tg" }
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg-${var.cluster_name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "frontend-tg" }
}


# Task Definitions
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image_uri
      essential = true

      portMappings = [{ containerPort = 3001, protocol = "tcp" }]

      environment = [
        { name = "PORT",                  value = "3001" },
        { name = "CLOUDINARY_CLOUD_NAME", value = "dhmmjyqza" },
        { name = "CLOUDINARY_API_KEY",    value = "442959675819781" }
      ]

      secrets = [
        { name = "MONGODB_URI",           valueFrom = "arn:aws:ssm:ap-south-1:${var.account_id}:parameter/curd-app/backend/MONGODB_URI" },
        { name = "JWT_SECRET",            valueFrom = "arn:aws:ssm:ap-south-1:${var.account_id}:parameter/curd-app/backend/JWT_SECRET" },
        { name = "CLOUDINARY_URL",        valueFrom = "arn:aws:ssm:ap-south-1:${var.account_id}:parameter/curd-app/backend/CLOUDINARY_URL" },
        { name = "CLOUDINARY_API_SECRET", valueFrom = "arn:aws:ssm:ap-south-1:${var.account_id}:parameter/curd-app/backend/CLOUDINARY_API_SECRET" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/backend"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image_uri
      essential = true

      portMappings = [{ containerPort = 80, protocol = "tcp" }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/frontend"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Services (with ALB attached)
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 3001
  }

  depends_on = [aws_lb_listener.backend_http]
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.frontend_http]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend"
  retention_in_days = 7
}

