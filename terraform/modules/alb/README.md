# terraform-aws-alb

Módulo Terraform para criar um **Application Load Balancer compartilhado** entre múltiplos serviços ECS, com roteamento por path e/ou host via listener rules.

## Recursos criados

- `aws_lb` – Application Load Balancer
- `aws_lb_target_group` – um por serviço declarado em `target_groups`
- `aws_lb_listener` – HTTP (80) sempre; HTTPS (443) se `https_certificate_arn` for informado
- `aws_lb_listener_rule` – uma por entrada em `listener_rules`
- `aws_lb_listener_certificate` – certificados SNI adicionais

## Uso

```hcl
module "alb" {
  source = "git::https://github.com/sua-org/terraform-aws-alb.git?ref=v1.0.0"

  name            = "producao-alb"
  vpc_id          = "vpc-xxxxxxxx"
  subnets         = ["subnet-pub1", "subnet-pub2"]
  security_groups = [aws_security_group.alb.id]

  https_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"
  http_to_https_redirect = true

  target_groups = {
    api = {
      port = 8080
      health_check = { path = "/health", matcher = "200" }
    }
    frontend = {
      port = 80
      health_check = { path = "/" }
    }
  }

  default_target_group = "frontend"

  listener_rules = {
    api = {
      priority      = 100
      target_group  = "api"
      path_patterns = ["/api/*"]
    }
  }

  tags = { Environment = "production" }
}

# Nos módulos de serviço ECS:
# target_group_arn = module.alb.target_group_arns["api"]
```

## Inputs principais

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `name` | `string` | – | Nome do ALB (máx 32 chars) |
| `vpc_id` | `string` | – | ID da VPC |
| `subnets` | `list(string)` | – | Subnets do ALB |
| `security_groups` | `list(string)` | `[]` | Security groups |
| `internal` | `bool` | `false` | ALB interno |
| `https_certificate_arn` | `string` | `null` | Certificado ACM (cria listener 443) |
| `extra_certificate_arns` | `list(string)` | `[]` | Certificados SNI adicionais |
| `http_to_https_redirect` | `bool` | `true` | Redireciona HTTP → HTTPS |
| `target_groups` | `any` | `{}` | Mapa de target groups por serviço |
| `default_target_group` | `string` | `null` | Chave do TG padrão (default action) |
| `listener_rules` | `any` | `{}` | Regras de roteamento |
| `deletion_protection` | `bool` | `false` | Proteção contra deleção |

## Outputs

| Output | Descrição |
|--------|-----------|
| `alb_arn` | ARN do ALB |
| `alb_dns_name` | DNS do ALB |
| `alb_zone_id` | Zone ID para Route53 alias |
| `alb_arn_suffix` | Sufixo para métricas de autoscaling |
| `target_group_arns` | Mapa `chave → ARN` de cada TG |
| `target_group_arn_suffixes` | Mapa `chave → arn_suffix` de cada TG |
| `http_listener_arn` | ARN do listener HTTP |
| `https_listener_arn` | ARN do listener HTTPS |
