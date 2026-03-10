###############################################################################
# Variáveis do Módulo ElastiCache Redis
###############################################################################

# ── Identificação ─────────────────────────────────────────────────────────────

variable "name" {
  description = "Nome base do recurso (usado como replication group ID e prefixo)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.name))
    error_message = "Nome deve ter 2-40 caracteres, apenas letras minúsculas, números e hífens."
  }
}

variable "name_prefix" {
  description = "Prefixo customizado. Se vazio, usa var.name"
  type        = string
  default     = ""
}

variable "description" {
  description = "Descrição do replication group"
  type        = string
  default     = "ElastiCache Redis managed by Terraform"
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

# ── Rede ──────────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "ID da VPC onde o Redis será criado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnet IDs para o subnet group"
  type        = list(string)
}

variable "port" {
  description = "Porta do Redis"
  type        = number
  default     = 6379
}

# ── Security Group ────────────────────────────────────────────────────────────

variable "create_security_group" {
  description = "Criar security group gerenciado pelo módulo"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "IDs de security groups externos (usado quando create_security_group = false)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups que podem acessar o Redis"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDRs que podem acessar o Redis"
  type        = list(string)
  default     = []
}

# ── Engine ────────────────────────────────────────────────────────────────────

variable "engine_version" {
  description = "Versão do Redis (ex: 7.1, 6.2)"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "Tipo de instância do Redis (ex: cache.t3.micro, cache.r6g.large)"
  type        = string
  default     = "cache.t3.micro"
}

# ── Topologia ─────────────────────────────────────────────────────────────────

variable "num_cache_nodes" {
  description = "Número total de nós (primary + replicas). Usado quando cluster_mode_enabled = false"
  type        = number
  default     = 1
}

variable "cluster_mode_enabled" {
  description = "Habilitar Redis Cluster Mode (sharding)"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Número de shards (cluster mode). Mínimo 1, máximo 500"
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Número de réplicas por shard (cluster mode). 0-5"
  type        = number
  default     = 1
}

variable "multi_az_enabled" {
  description = "Habilitar Multi-AZ com failover automático"
  type        = bool
  default     = false
}

variable "automatic_failover_enabled" {
  description = "Habilitar failover automático (requer num_cache_nodes >= 2)"
  type        = bool
  default     = false
}

# ── Parameter Group ───────────────────────────────────────────────────────────

variable "create_parameter_group" {
  description = "Criar parameter group gerenciado pelo módulo"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Nome do parameter group externo (usado quando create_parameter_group = false)"
  type        = string
  default     = ""
}

variable "parameter_group_family" {
  description = "Família do parameter group (ex: redis7, redis6.x)"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "Lista de parâmetros customizados"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# ── Segurança ─────────────────────────────────────────────────────────────────

variable "at_rest_encryption_enabled" {
  description = "Habilitar criptografia em repouso"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Habilitar TLS em trânsito (requer auth_token se habilitado)"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Token de autenticação Redis (AUTH). Obrigatório quando transit_encryption_enabled = true"
  type        = string
  default     = ""
  sensitive   = true
}

# ── Backup ────────────────────────────────────────────────────────────────────

variable "snapshot_retention_limit" {
  description = "Dias de retenção de snapshots automáticos (0 = desabilitado)"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Janela de tempo para snapshots automáticos (UTC). Ex: '05:00-06:00'"
  type        = string
  default     = "03:00-04:00"
}

variable "final_snapshot_identifier" {
  description = "Nome do snapshot final ao destruir o cluster (vazio = sem snapshot)"
  type        = string
  default     = ""
}

variable "snapshot_name" {
  description = "Nome de snapshot existente para restaurar o cluster"
  type        = string
  default     = ""
}

# ── Manutenção ────────────────────────────────────────────────────────────────

variable "maintenance_window" {
  description = "Janela de manutenção semanal (UTC). Ex: 'sun:05:00-sun:06:00'"
  type        = string
  default     = "sun:02:00-sun:03:00"
}

variable "auto_minor_version_upgrade" {
  description = "Atualizar versões minor automaticamente"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Aplicar mudanças imediatamente (false = próxima janela de manutenção)"
  type        = bool
  default     = false
}

variable "notification_topic_arn" {
  description = "ARN do SNS topic para notificações de eventos"
  type        = string
  default     = ""
}

# ── Logs ──────────────────────────────────────────────────────────────────────

variable "slow_log_destination" {
  description = "ARN do CloudWatch Logs group ou Kinesis Firehose para slow logs"
  type        = string
  default     = ""
}

variable "slow_log_destination_type" {
  description = "Tipo de destino para slow logs: cloudwatch-logs ou kinesis-firehose"
  type        = string
  default     = "cloudwatch-logs"
}

variable "slow_log_format" {
  description = "Formato dos slow logs: text ou json"
  type        = string
  default     = "json"
}

variable "engine_log_destination" {
  description = "ARN do CloudWatch Logs group ou Kinesis Firehose para engine logs"
  type        = string
  default     = ""
}

variable "engine_log_destination_type" {
  description = "Tipo de destino para engine logs: cloudwatch-logs ou kinesis-firehose"
  type        = string
  default     = "cloudwatch-logs"
}

variable "engine_log_format" {
  description = "Formato dos engine logs: text ou json"
  type        = string
  default     = "json"
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

variable "create_cloudwatch_alarms" {
  description = "Criar alarmes CloudWatch para CPU, memória e conexões"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "Lista de ARNs para notificação quando alarme disparar (ex: SNS topic)"
  type        = list(string)
  default     = []
}

variable "alarm_cpu_threshold" {
  description = "Threshold de CPU (%) para disparar alarme"
  type        = number
  default     = 75
}

variable "alarm_memory_threshold_bytes" {
  description = "Threshold mínimo de memória livre (bytes) para disparar alarme (padrão: 100MB)"
  type        = number
  default     = 104857600
}

variable "alarm_connections_threshold" {
  description = "Threshold de conexões simultâneas para disparar alarme"
  type        = number
  default     = 1000
}
