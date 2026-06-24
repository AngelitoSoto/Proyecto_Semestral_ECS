resource "aws_ecs_cluster" "main" {
  name = "semestral-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Variable para el LabRole de AWS Academy
variable "lab_role_arn" {
  type    = string
  default = "arn:aws:iam::549642143837:role/LabRole"
}

# Grupo de Logs único en CloudWatch
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/semestral-app"
  retention_in_days = 7
}

# ==================== MULTI-CONTAINER TASK DEFINITION ====================

resource "aws_ecs_task_definition" "app" {
  family                   = "semestral-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU completo compartido
  memory                   = "2048" # 2 GB RAM compartido
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    # 1. MySQL Container (con Health Check)
    {
      name      = "mysql"
      image     = "mysql:8.0"
      essential = true
      portMappings = [
        {
          containerPort = 3306
          hostPort      = 3306
        }
      ]
      environment = [
        { name = "MYSQL_ROOT_PASSWORD", value = "root" },
        { name = "MYSQL_DATABASE", value = "semestraldb" }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "mysqladmin ping -h localhost -uroot -proot"]
        interval    = 5
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "mysql"
        }
      }
    },
    # 2. Ventas Backend Container (depende de MySQL HEALTHY)
    {
      name      = "ventas"
      image     = "${aws_ecr_repository.ventas.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      environment = [
        { name = "DB_ENDPOINT", value = "127.0.0.1" },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = "semestraldb" },
        { name = "DB_USERNAME", value = "root" },
        { name = "DB_PASSWORD", value = "root" }
      ]
      dependsOn = [
        {
          containerName = "mysql"
          condition     = "HEALTHY"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ventas"
        }
      }
    },
    # 3. Despachos Backend Container (depende de MySQL HEALTHY)
    {
      name      = "despachos"
      image     = "${aws_ecr_repository.despachos.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      environment = [
        { name = "DB_ENDPOINT", value = "127.0.0.1" },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = "semestraldb" },
        { name = "DB_USERNAME", value = "root" },
        { name = "DB_PASSWORD", value = "root" }
      ]
      dependsOn = [
        {
          containerName = "mysql"
          condition     = "HEALTHY"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "despachos"
        }
      }
    },
    # 4. Frontend Container (depende de los Backends)
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      dependsOn = [
        {
          containerName = "ventas"
          condition     = "START"
        },
        {
          containerName = "despachos"
          condition     = "START"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])
}

# ==================== ECS SERVICE ====================

resource "aws_ecs_service" "app" {
  name            = "semestral-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }
}
