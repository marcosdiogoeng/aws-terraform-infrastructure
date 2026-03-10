# Módulo Terraform — CloudFront Reutilizável

Módulo Terraform para criar distribuições CloudFront na AWS com suporte completo a múltiplas origens, comportamentos de cache, WAF, SSL, failover e muito mais.

## Funcionalidades

| Recurso                           | Suporte |
|-----------------------------------|---------|
| Origins S3 com OAC automático     | ✅      |
| Origins customizados (ALB, API GW)| ✅      |
| Grupos de origem com failover     | ✅      |
| Múltiplos comportamentos de cache | ✅      |
| Cache Policies gerenciadas (AWS)  | ✅      |
| Certificado SSL/TLS (ACM)         | ✅      |
| Domínios customizados (aliases)   | ✅      |
| Páginas de erro customizadas      | ✅      |
| Restrições geográficas            | ✅      |
| AWS WAF (WebACL)                  | ✅      |
| CloudFront Functions / Lambda@Edge| ✅      |
| Logs de acesso                    | ✅      |
| IPv6                              | ✅      |
| HTTP/2 e HTTP/3                   | ✅      |
| Bucket Policy S3 via OAC         | ✅      |

---

## Uso Básico

```hcl
module "cdn" {
  source = "./terraform-cloudfront-module"

  distribution_name   = "meu-site"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc"
  aliases             = ["meusite.com"]

  s3_origins = [
    {
      origin_id   = "s3-site"
      domain_name = aws_s3_bucket.site.bucket_regional_domain_name
      bucket_id   = aws_s3_bucket.site.id
      bucket_arn  = aws_s3_bucket.site.arn
    }
  ]

  default_cache_behavior = {
    target_origin_id = "s3-site"
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }
}
```

---

## Políticas Gerenciadas pela AWS (referência)

O arquivo `managed_policies.tf` contém locals com os IDs das políticas mais usadas:

### Cache Policies
| Nome | ID |
|------|-----|
| `CachingOptimized` (S3 estático) | `658327ea-f89d-4fab-a63d-7e88639e58f6` |
| `CachingDisabled` (APIs dinâmicas) | `4135ea2d-6df8-44a3-9df3-4b5a84be39ad` |

### Origin Request Policies
| Nome | ID |
|------|-----|
| `CORS-S3Origin` | `88a5eaf4-2fd4-4709-b370-b4c650ea3fcf` |
| `AllViewer` | `216adef6-5c7f-47e4-b989-5492eafa07d3` |

### Response Headers Policies
| Nome | ID |
|------|-----|
| `SecurityHeadersPolicy` | `67f7725c-6f97-4210-82d7-5512b31e9d03` |

---

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `distribution_name` | Nome lógico da distribuição | `string` | — | ✅ |
| `default_cache_behavior` | Comportamento de cache padrão | `any` | — | ✅ |
| `s3_origins` | Origins S3 com OAC automático | `any` | `[]` | não |
| `custom_origins` | Origins customizados (ALB, etc.) | `any` | `[]` | não |
| `origin_groups` | Grupos de failover | `any` | `[]` | não |
| `ordered_cache_behaviors` | Comportamentos adicionais ordenados | `any` | `[]` | não |
| `custom_error_responses` | Páginas de erro customizadas | `any` | `[]` | não |
| `aliases` | Domínios customizados (requer ACM) | `list(string)` | `[]` | não |
| `acm_certificate_arn` | ARN do certificado ACM (us-east-1) | `string` | `null` | não |
| `minimum_protocol_version` | Versão mínima TLS | `string` | `TLSv1.2_2021` | não |
| `web_acl_id` | ARN do WAF WebACL | `string` | `null` | não |
| `price_class` | Classe de preço | `string` | `PriceClass_All` | não |
| `http_version` | Versão HTTP máxima | `string` | `http2and3` | não |
| `geo_restriction_type` | Tipo de geo-restriction | `string` | `none` | não |
| `geo_restriction_locations` | Países para geo-restriction | `list(string)` | `[]` | não |
| `logging_bucket` | Bucket de logs (domínio .s3.amazonaws.com) | `string` | `null` | não |
| `logging_prefix` | Prefixo dos logs | `string` | `cloudfront/` | não |
| `enabled` | Habilita a distribuição | `bool` | `true` | não |
| `ipv6_enabled` | Habilita IPv6 | `bool` | `true` | não |
| `default_root_object` | Objeto raiz padrão | `string` | `index.html` | não |
| `tags` | Tags adicionais | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `distribution_id` | ID da distribuição |
| `distribution_arn` | ARN da distribuição |
| `distribution_domain_name` | Domínio CloudFront (dXXX.cloudfront.net) |
| `distribution_hosted_zone_id` | Hosted Zone ID para Route53 Alias |
| `distribution_etag` | ETag da distribuição |
| `distribution_status` | Status: Deployed / InProgress |
| `oac_ids` | Map de OAC IDs criados |

---

## Exemplos

| Caso de uso | Localização |
|-------------|-------------|
| Site estático SPA com S3 + OAC | `examples/complete/main.tf` |
| Fullstack: assets S3 + API ALB | `examples/complete/main.tf` |
| WAF + Geo-Restriction + Failover | `examples/complete/main.tf` |

---

## Estrutura

```
terraform-cloudfront-module/
├── main.tf                  # Recursos CloudFront + OAC + S3 policy
├── variables.tf             # Variáveis com descrições em PT-BR
├── outputs.tf               # Outputs
├── versions.tf              # Versões requeridas
├── managed_policies.tf      # Referência de policy IDs gerenciados pela AWS
├── README.md
└── examples/
    └── complete/
        └── main.tf          # 3 exemplos prontos para uso
```

## Requisitos

- Terraform `>= 1.3.0`
- AWS Provider `>= 5.0`
- Certificado ACM **deve estar na região `us-east-1`**
