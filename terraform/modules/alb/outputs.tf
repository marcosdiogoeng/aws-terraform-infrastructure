# ==============================================================================
# terraform-aws-alb – Outputs
# ==============================================================================

output "alb_arn" {
  description = "ARN do ALB"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name do ALB"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 hosted zone ID do ALB (para alias records)"
  value       = aws_lb.this.zone_id
}

output "alb_id" {
  description = "ID do ALB"
  value       = aws_lb.this.id
}

output "http_listener_arn" {
  description = "ARN do listener HTTP (porta 80)"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN do listener HTTPS (porta 443). Null se não houver certificado"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

output "target_group_arns" {
  description = "Mapa de chave → ARN de cada target group criado"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "target_group_names" {
  description = "Mapa de chave → nome de cada target group criado"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.name }
}

# Usado pelo autoscaling de ALB Request Count
output "alb_arn_suffix" {
  description = "Sufixo do ARN do ALB (usado em métricas do CloudWatch/Autoscaling)"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffixes" {
  description = "Mapa de chave → arn_suffix de cada target group (usado em métricas)"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn_suffix }
}
