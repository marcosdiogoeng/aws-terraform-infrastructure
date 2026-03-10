variable "bucket_name" {
  description = "Nome do bucket S3. Deve ser globalmente único."
  type        = string
}

variable "force_destroy" {
  description = "Permite destruir o bucket mesmo com objetos dentro."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags adicionais aplicadas ao bucket."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Habilita versionamento de objetos."
  type        = bool
  default     = false
}

variable "sse_enabled" {
  description = "Habilita criptografia Server-Side (AES256 ou KMS)."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN da chave KMS. Se null, usa AES256."
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Bloqueia todo acesso público ao bucket."
  type        = bool
  default     = true
}

variable "bucket_policy" {
  description = "JSON da política do bucket. Use jsonencode() ou templatefile()."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = <<EOF
Lista de regras de ciclo de vida. Exemplo:
[
  {
    id      = "mover-para-ia"
    enabled = true
    prefix  = "logs/"
    transitions = [
      { days = 30,  storage_class = "STANDARD_IA" },
      { days = 90,  storage_class = "GLACIER" }
    ]
    expiration_days                   = 365
    noncurrent_version_expiration_days = 30
  }
]
EOF
  type        = any
  default     = []
}

variable "cors_rules" {
  description = <<EOF
Regras CORS. Exemplo:
[
  {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://meusite.com"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
]
EOF
  type        = any
  default     = []
}

variable "logging_bucket" {
  description = "Nome do bucket de destino para logs de acesso."
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefixo dos logs. Padrão: <bucket_name>/."
  type        = string
  default     = null
}

variable "website_enabled" {
  description = "Habilita hospedagem de site estático."
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "Documento index do site estático."
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Documento de erro do site estático."
  type        = string
  default     = null
}

variable "notification_sqs" {
  description = "Notificações S3 para filas SQS."
  type        = any
  default     = []
}

variable "notification_sns" {
  description = "Notificações S3 para tópicos SNS."
  type        = any
  default     = []
}

variable "notification_lambda" {
  description = "Notificações S3 para funções Lambda."
  type        = any
  default     = []
}
