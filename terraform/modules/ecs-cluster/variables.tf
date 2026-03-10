
variable "name" {
  description = "Nome do cluster ECS"
  type        = string
}

variable "container_insights" {
  description = "Habilita Container Insights (métricas de CPU, memória, rede por task/serviço)"
  type        = bool
  default     = false
}

variable "capacity_providers" {
  description = <<-EOT
    Lista de capacity providers associados ao cluster.
    Use ["FARGATE", "FARGATE_SPOT"] para Fargate gerenciado.
    Para EC2, informe o nome do Auto Scaling Group capacity provider criado separadamente.
  EOT
  type        = list(string)
  default     = []
}

variable "default_capacity_provider_strategy" {
  description = <<-EOT
    Estratégia padrão de capacity provider para tasks sem launch_type explícito.

    Exemplo:
      [
        { capacity_provider = "FARGATE",      weight = 1, base = 1 },
        { capacity_provider = "FARGATE_SPOT", weight = 4, base = 0 }
      ]
  EOT
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = []
}

# ── KMS ────────────────────────────────────────────────────────────────────────
variable "create_kms_key" {
  description = "Cria uma KMS key dedicada para criptografia de dados do cluster"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "Dias de janela de deleção da KMS key (7-30)"
  type        = number
  default     = 7
}

# ── ECS Exec ───────────────────────────────────────────────────────────────────
variable "create_exec_log_group" {
  description = "Cria CloudWatch Log Group para auditoria do ECS Exec"
  type        = bool
  default     = false
}

variable "exec_log_retention_days" {
  description = "Retenção dos logs de auditoria do ECS Exec em dias"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
