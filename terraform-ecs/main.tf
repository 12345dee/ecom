provider "aws" { region = var.aws_region }
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" { filter { name = "vpc-id" values = [data.aws_vpc.default.id] } }
resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-sg"
  vpc_id      = data.aws_vpc.default.id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = [var.cidr_allow] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "task_sg" {
  name   = "${var.app_name}-task-sg"
  vpc_id = data.aws_vpc.default.id
  ingress { from_port = 3000 to_port = 3000 protocol = "tcp" security_groups = [aws_security_group.alb_sg.id] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}
resource "aws_lb_target_group" "tg_blue" {
  name     = "${var.app_name}-tg-blue"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check { path = "/health" healthy_threshold = 2 unhealthy_threshold = 3 interval = 15 matcher = "200-399" }
}
resource "aws_lb_target_group" "tg_green" {
  name     = "${var.app_name}-tg-green"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check { path = "/health" healthy_threshold = 2 unhealthy_threshold = 3 interval = 15 matcher = "200-399" }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action { type = "forward" target_group_arn = aws_lb_target_group.tg_blue.arn }
}
resource "aws_ecr_repository" "repo" {
  name = "${var.app_name}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}
resource "aws_ecs_cluster" "cluster" { name = "${var.app_name}-cluster" }
data "aws_iam_policy_document" "ecs_task_assume" {
  statement { actions = ["sts:AssumeRole"] principals { type = "Service"  identifiers = ["ecs-tasks.amazonaws.com"] } }
}
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "ecs" { name = "/ecs/${var.app_name}" retention_in_days = 14 }
resource "aws_ecs_task_definition" "td_blue" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions    = jsonencode([{
    name      = "${var.app_name}"
    image     = "${aws_ecr_repository.repo.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 3000 protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.ecs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = var.app_name
      }
    }
  }])
}
resource "aws_ecs_service" "blue" {
  name            = "${var.app_name}-blue"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.td_blue.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.task_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.tg_blue.arn
    container_name   = var.app_name
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.http]
}
resource "aws_ecs_service" "green" {
  name            = "${var.app_name}-green"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.td_blue.arn
  desired_count   = 0
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.task_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.tg_green.arn
    container_name   = var.app_name
    container_port   = 3000
  }
}
