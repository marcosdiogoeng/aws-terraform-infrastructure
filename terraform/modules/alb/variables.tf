# ==============================================================================
# terraform-aws-alb – Variables
# ==============================================================================

variable "name" {
  description = "Nome do ALB (máx 32 caracteres)"
  type        = string
  validation {
    condition     = length(var.name) <= 32
    error_message = "O nome do ALB não pode ultrapassar 32 caracteres."
  }
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnets" {
  description = "Lista de subnets públicas (ou privadas para ALB interno)"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups atribuídos ao ALB"
  type        = list(string)
  default     = []
}

variable "internal" {
  description = "true = ALB interno; false = internet-facing"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Timeout de conexão idle em segundos"
  type        = number
  default     = 60
}

variable "deletion_protection" {
  description = "Habilita proteção contra deleção acidental"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Habilita balanceamento entre zonas"
  type        = bool
  default     = true
}

variable "drop_invalid_header_fields" {
  description = "Descarta headers HTTP inválidos"
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Configuração de access logs no S3. Ex: { bucket = 'meu-bucket', prefix = 'alb/' }"
  type        = any
  default     = {}
}

# ── HTTPS / TLS ────────────────────────────────────────────────────────────────
variable "https_certificate_arn" {
  description = "ARN do certificado ACM principal. Se informado, cria listener HTTPS na porta 443"
  type        = string
  default     = null
}

variable "extra_certificate_arns" {
  description = "ARNs de certificados adicionais para SNI (múltiplos domínios no mesmo ALB)"
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "Política TLS do listener HTTPS"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "http_to_https_redirect" {
  description = "Redireciona automaticamente HTTP → HTTPS (requer https_certificate_arn)"
  type        = bool
  default     = true
}

# ── Target Groups ──────────────────────────────────────────────────────────────
variable "target_groups" {
  description = <<-EOT
    Mapa de target groups. A chave é o identificador lógico usado nas listener_rules.

    Campos por target group:
      name                 (string) – nome do TG; padrão: "<alb-name>-<chave>"
      port                 (number) – porta do container (obrigatório)
      protocol             (string) – HTTP | HTTPS; padrão: HTTP
      target_type          (string) – ip | instance | lambda; padrão: ip
      deregistration_delay (number) – segundos para drenar conexões; padrão: 30
      health_check:
        path                (string) – padrão: "/"
        matcher             (string) – padrão: "200-299"
        healthy_threshold   (number) – padrão: 3
        unhealthy_threshold (number) – padrão: 3
        interval            (number) – padrão: 30
        timeout             (number) – padrão: 5
      stickiness:
        enabled         (bool)
        type            (string) – padrão: lb_cookie
        cookie_duration (number) – padrão: 86400

    Exemplo:
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
  EOT
  type        = any
  default     = {}
}

variable "default_target_group" {
  description = "Chave do target group padrão (default action do listener). Se null, responde 404 para rotas não mapeadas"
  type        = string
  default     = null
}

# ── Listener Rules ─────────────────────────────────────────────────────────────
variable "listener_rules" {
  description = <<-EOT
    Mapa de listener rules para roteamento. A chave é o identificador da regra.

    Campos por rule:
      priority       (number)       – prioridade única entre 1-50000 (obrigatório)
      target_group   (string)       – chave de var.target_groups (obrigatório)
      path_patterns  (list(string)) – ex: ["/api/*", "/v1/*"]
      host_headers   (list(string)) – ex: ["api.exemplo.com"]
      http_methods   (list(string)) – ex: ["GET", "POST"]

    Exemplo:
      listener_rules = {
        api = {
          priority     = 100
          target_group = "api"
          path_patterns = ["/api/*"]
        }
        frontend = {
          priority     = 200
          target_group = "frontend"
          host_headers = ["app.exemplo.com"]
        }
      }
  EOT
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
