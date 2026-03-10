# Variables for IAM Module

# Common
variable "tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default     = {}
}

# IAM User
variable "create_user" {
  description = "Se deve criar um usuário IAM"
  type        = bool
  default     = false
}

variable "user_name" {
  description = "Nome do usuário IAM"
  type        = string
  default     = ""
}

variable "user_path" {
  description = "Path do usuário IAM"
  type        = string
  default     = "/"
}

# IAM Policy
variable "create_custom_policy" {
  description = "Se deve criar uma policy customizada"
  type        = bool
  default     = false
}

variable "policy_name" {
  description = "Nome da policy IAM"
  type        = string
  default     = ""
}

variable "policy_path" {
  description = "Path da policy IAM"
  type        = string
  default     = "/"
}

variable "policy_description" {
  description = "Descrição da policy IAM"
  type        = string
  default     = "Custom IAM Policy"
}

variable "policy_json_file" {
  description = "Caminho para o arquivo JSON com a policy"
  type        = string
  default     = ""
}

variable "policy_json_content" {
  description = "Conteúdo JSON da policy (alternativa ao arquivo)"
  type        = string
  default     = ""
}

variable "attach_custom_policy_to_user" {
  description = "Se deve anexar a policy customizada ao usuário"
  type        = bool
  default     = false
}

variable "attach_custom_policy_to_role" {
  description = "Se deve anexar a policy customizada à role"
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = "Lista de ARNs de policies AWS gerenciadas para anexar ao usuário"
  type        = list(string)
  default     = []
}

# IAM Role
variable "create_role" {
  description = "Se deve criar uma role IAM"
  type        = bool
  default     = false
}

variable "role_name" {
  description = "Nome da role IAM"
  type        = string
  default     = ""
}

variable "role_path" {
  description = "Path da role IAM"
  type        = string
  default     = "/"
}

variable "role_description" {
  description = "Descrição da role IAM"
  type        = string
  default     = "IAM Role"
}

variable "assume_role_policy_json" {
  description = "JSON da assume role policy (inline)"
  type        = string
  default     = ""
}

variable "assume_role_policy_file" {
  description = "Caminho para o arquivo JSON com a assume role policy"
  type        = string
  default     = ""
}

variable "role_max_session_duration" {
  description = "Duração máxima da sessão em segundos"
  type        = number
  default     = 3600
}

variable "role_managed_policy_arns" {
  description = "Lista de ARNs de policies AWS gerenciadas para anexar à role"
  type        = list(string)
  default     = []
}

# IAM Access Key
variable "create_access_key" {
  description = "Se deve criar access key para o usuário"
  type        = bool
  default     = false
}
