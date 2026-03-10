variable "distribution_name" {
  description = "Nome lógico da distribuição (usado em tags e no nome do OAC)."
  type        = string
}

variable "enabled" {
  description = "Habilita ou desabilita a distribuição."
  type        = bool
  default     = true
}

variable "ipv6_enabled" {
  description = "Habilita suporte a IPv6."
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comentário descritivo da distribuição."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Objeto raiz padrão (ex: index.html)."
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "CNAMEs alternativos (domínios customizados). Requer certificado ACM."
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "Classe de preço da distribuição."
  type        = string
  default     = "PriceClass_All"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class deve ser: PriceClass_All, PriceClass_200, ou PriceClass_100."
  }
}

variable "http_version" {
  description = "Versão máxima do protocolo HTTP suportada."
  type        = string
  default     = "http2and3"
  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version deve ser: http1.1, http2, http2and3, ou http3."
  }
}

variable "web_acl_id" {
  description = "ARN do AWS WAF WebACL a ser associado à distribuição."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}

# ---------- Origins S3 ----------
variable "s3_origins" {
  description = <<EOF
Lista de origins S3. Exemplo:
[
  {
    origin_id   = "s3-meu-site"
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    bucket_id   = aws_s3_bucket.this.id       # necessário para criar a bucket policy
    bucket_arn  = aws_s3_bucket.this.arn       # necessário para criar a bucket policy
    create_oac  = true                          # cria OAC automaticamente (padrão: true)
    origin_path = "/static"                     # opcional
    custom_headers = [
      { name = "X-Custom-Header", value = "valor" }
    ]
  }
]
EOF
  type        = any
  default     = []
}

# ---------- Origins Customizados ----------
variable "custom_origins" {
  description = <<EOF
Lista de origins customizados (ALB, API Gateway, HTTP). Exemplo:
[
  {
    origin_id               = "alb-api"
    domain_name             = "api.meusite.com"
    origin_protocol_policy  = "https-only"
    origin_ssl_protocols    = ["TLSv1.2"]
    http_port               = 80
    https_port              = 443
    origin_read_timeout     = 30
    origin_keepalive_timeout = 5
    custom_headers = [
      { name = "X-Origin-Verify", value = "segredo" }
    ]
  }
]
EOF
  type        = any
  default     = []
}

# ---------- Grupos de Origem (Failover) ----------
variable "origin_groups" {
  description = <<EOF
Grupos de origem para failover. Exemplo:
[
  {
    origin_id           = "grupo-failover"
    primary_origin_id   = "s3-primary"
    failover_origin_id  = "s3-failover"
    status_codes        = [500, 502, 503, 504]
  }
]
EOF
  type        = any
  default     = []
}

# ---------- Comportamento Padrão ----------
variable "default_cache_behavior" {
  description = <<EOF
Comportamento de cache padrão. Exemplo com Cache Policy (recomendado):
{
  target_origin_id         = "s3-meu-site"
  viewer_protocol_policy   = "redirect-to-https"
  cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
  origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"  # CORS-S3Origin
  compress                 = true
}

Exemplo com TTL manual:
{
  target_origin_id       = "alb-api"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  forward_query_string   = true
  forward_cookies        = "all"
  default_ttl            = 0
  min_ttl                = 0
  max_ttl                = 0
}
EOF
  type        = any
}

# ---------- Comportamentos Ordenados ----------
variable "ordered_cache_behaviors" {
  description = <<EOF
Comportamentos de cache adicionais ordenados por prioridade. Exemplo:
[
  {
    path_pattern           = "/api/*"
    target_origin_id       = "alb-api"
    viewer_protocol_policy = "https-only"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingDisabled
    compress               = false
  },
  {
    path_pattern     = "/static/*"
    target_origin_id = "s3-assets"
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
  }
]
EOF
  type        = any
  default     = []
}

# ---------- Erros Customizados ----------
variable "custom_error_responses" {
  description = <<EOF
Páginas de erro customizadas. Exemplo:
[
  {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  },
  {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }
]
EOF
  type        = any
  default     = []
}

# ---------- SSL / HTTPS ----------
variable "acm_certificate_arn" {
  description = "ARN do certificado ACM (deve estar em us-east-1). Se null, usa o certificado padrão do CloudFront."
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Versão mínima do protocolo TLS quando usar ACM."
  type        = string
  default     = "TLSv1.2_2021"
}

# ---------- Restrições Geográficas ----------
variable "geo_restriction_type" {
  description = "Tipo de restrição geográfica: none, whitelist, blacklist."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type deve ser: none, whitelist ou blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "Lista de códigos de país ISO 3166-1 alpha-2 para geo restriction."
  type        = list(string)
  default     = []
}

# ---------- Logging ----------
variable "logging_bucket" {
  description = "Domínio do bucket de logs (ex: meu-bucket-logs.s3.amazonaws.com)."
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefixo dos logs no bucket."
  type        = string
  default     = "cloudfront/"
}

variable "logging_include_cookies" {
  description = "Inclui cookies nos logs de acesso."
  type        = bool
  default     = false
}
