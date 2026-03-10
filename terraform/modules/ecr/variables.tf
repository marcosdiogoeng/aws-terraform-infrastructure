# ==============================================================================
# Required
# ==============================================================================

variable "repository_name" {
  description = "Nome do repositório ECR."
  type        = string
}

# ==============================================================================
# Repository Settings
# ==============================================================================

variable "image_tag_mutability" {
  description = "Mutabilidade das tags de imagem. Valores: MUTABLE | IMMUTABLE."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability deve ser MUTABLE ou IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Habilita escaneamento de vulnerabilidades ao fazer push de imagens."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Tipo de criptografia do repositório. Valores: AES256 | KMS."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type deve ser AES256 ou KMS."
  }
}

variable "kms_key_arn" {
  description = "ARN da chave KMS. Obrigatório quando encryption_type = KMS."
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Permite deletar o repositório mesmo com imagens. Use com cuidado."
  type        = bool
  default     = false
}

# ==============================================================================
# Lifecycle Policy
# ==============================================================================

variable "enable_default_lifecycle_policy" {
  description = "Habilita a lifecycle policy padrão (tagged + untagged rules)."
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "JSON de lifecycle policy customizado. Se definido, sobrescreve a policy padrão."
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Número máximo de imagens tagged a manter (usada na policy padrão)."
  type        = number
  default     = 10
}

variable "untagged_image_days" {
  description = "Dias para expirar imagens sem tag (usada na policy padrão)."
  type        = number
  default     = 7
}

variable "lifecycle_tag_prefixes" {
  description = "Prefixos de tag para a regra de retenção na policy padrão."
  type        = list(string)
  default     = ["v"]
}

# ==============================================================================
# Repository Policy
# ==============================================================================

variable "repository_policy" {
  description = "JSON de IAM policy para o repositório (acesso cross-account, ECS, etc.)."
  type        = string
  default     = null
}

# ==============================================================================
# Replication
# ==============================================================================

variable "replication_destinations" {
  description = "Lista de destinos para replicação de imagens."
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
}

variable "replication_filters" {
  description = "Filtros de repositório para replicação."
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  description = "Mapa de tags aplicadas a todos os recursos."
  type        = map(string)
  default     = {}
}
