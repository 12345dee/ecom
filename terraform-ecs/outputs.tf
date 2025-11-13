output "alb_dns" { value = aws_lb.app_alb.dns_name }
output "ecr_repo" { value = aws_ecr_repository.repo.repository_url }
output "cluster_name" { value = aws_ecs_cluster.cluster.name }
output "tg_blue_arn" { value = aws_lb_target_group.tg_blue.arn }
output "tg_green_arn" { value = aws_lb_target_group.tg_green.arn }
