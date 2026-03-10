###############################################################################
# VPC
###############################################################################
variable "name" {
  description = "Prefixo usado nos nomes de todos os recursos."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR principal da VPC."
  type        = string
}

variable "enable_dns_support" {
  description = "Habilita suporte a DNS na VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Habilita hostnames DNS na VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos."
  type        = map(string)
  default     = {}
}

###############################################################################
# Internet Gateway
###############################################################################
variable "create_igw" {
  description = "Cria o Internet Gateway. Desabilite se a VPC for totalmente privada."
  type        = bool
  default     = true
}

###############################################################################
# Subnets
###############################################################################
variable "public_subnets" {
  description = <<-EOT
    Lista de subnets públicas.
    Cada objeto deve conter:
      - name  (string)  : nome único da subnet (usado como chave e sufixo no Name tag)
      - cidr  (string)  : bloco CIDR
      - az    (string)  : availability zone (ex: "us-east-1a")
      - map_public_ip_on_launch (bool, opcional, default true)
  EOT
  type = list(object({
    name                    = string
    cidr                    = string
    az                      = string
    map_public_ip_on_launch = optional(bool, true)
  }))
  default = []
}

variable "private_subnets" {
  description = <<-EOT
    Lista de subnets privadas.
    Cada objeto deve conter:
      - name  (string) : nome único da subnet
      - cidr  (string) : bloco CIDR
      - az    (string) : availability zone
  EOT
  type = list(object({
    name = string
    cidr = string
    az   = string
  }))
  default = []
}

###############################################################################
# Rotas extras — Route Table Pública
###############################################################################
variable "public_extra_routes" {
  description = <<-EOT
    Rotas adicionais inseridas na route table pública (além da rota padrão para o IGW).
    Campos obrigatórios:
      - destination_cidr_block (string)
    Campos opcionais (preencha apenas UM por entrada):
      - gateway_id
      - nat_gateway_id
      - transit_gateway_id
      - vpc_peering_connection_id
      - network_interface_id
  EOT
  type = list(object({
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  default = []
}

###############################################################################
# NAT Gateway
###############################################################################
variable "create_nat_gateway" {
  description = "Cria NAT Gateway(s) para as subnets privadas. Requer create_igw = true e ao menos uma subnet pública."
  type        = bool
  default     = false
}

variable "nat_gateway_ha" {
  description = <<-EOT
    Modo de alta disponibilidade do NAT Gateway.
    - true  → cria um NAT Gateway por AZ (das subnets públicas) — recomendado para produção.
    - false → cria um único NAT Gateway na primeira subnet pública — mais econômico.
  EOT
  type        = bool
  default     = false
}

###############################################################################
# Rotas extras — Route Tables Privadas
###############################################################################
variable "private_extra_routes" {
  description = <<-EOT
    Rotas adicionais inseridas nas route tables privadas.
    Campos obrigatórios:
      - subnet_name            (string) : nome da subnet privada alvo (deve bater com private_subnets[*].name)
      - destination_cidr_block (string)
    Campos opcionais (preencha apenas UM por entrada):
      - gateway_id
      - nat_gateway_id
      - transit_gateway_id
      - vpc_peering_connection_id
      - network_interface_id
  EOT
  type = list(object({
    subnet_name               = string
    destination_cidr_block    = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  default = []
}