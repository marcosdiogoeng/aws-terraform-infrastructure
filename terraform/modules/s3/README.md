# Módulo Terraform — S3 Reutilizável

Módulo Terraform para criar buckets S3 na AWS com suporte a todas as configurações mais comuns de produção.

## Funcionalidades

| Recurso                    | Suporte |
|----------------------------|---------|
| Versionamento              | ✅      |
| Criptografia SSE (AES/KMS) | ✅      |
| Bloqueio de acesso público | ✅      |
| Bucket Policy customizada  | ✅      |
| Regras de ciclo de vida    | ✅      |
| CORS                       | ✅      |
| Logs de acesso             | ✅      |
| Site estático              | ✅      |
| Notificações SQS/SNS/Lambda| ✅      |

---

## Uso Básico

```hcl
module "s3" {
  source = "./terraform-s3-module"

  bucket_name        = "meu-bucket-prod"
  versioning_enabled = true
  sse_enabled        = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Exemplo Completo

Veja `examples/complete/main.tf` para exemplos de:
- Bucket de dados com KMS + ciclo de vida
- Site estático com CORS e policy pública
- Bucket com notificações SQS

---

## Inputs

| Nome                              | Descrição                                       | Tipo     | Default  | Obrigatório |
|-----------------------------------|-------------------------------------------------|----------|----------|:-----------:|
| `bucket_name`                     | Nome global único do bucket                     | `string` | —        | ✅ sim      |
| `force_destroy`                   | Destrói bucket mesmo com objetos                | `bool`   | `false`  | não         |
| `versioning_enabled`              | Habilita versionamento                          | `bool`   | `false`  | não         |
| `sse_enabled`                     | Habilita criptografia SSE                       | `bool`   | `true`   | não         |
| `kms_key_arn`                     | ARN da chave KMS (null = AES256)                | `string` | `null`   | não         |
| `block_public_access`             | Bloqueia acesso público                         | `bool`   | `true`   | não         |
| `bucket_policy`                   | JSON da política do bucket                      | `string` | `null`   | não         |
| `lifecycle_rules`                 | Lista de regras de ciclo de vida                | `any`    | `[]`     | não         |
| `cors_rules`                      | Regras CORS                                     | `any`    | `[]`     | não         |
| `logging_bucket`                  | Bucket destino dos logs de acesso               | `string` | `null`   | não         |
| `logging_prefix`                  | Prefixo dos logs                                | `string` | `null`   | não         |
| `website_enabled`                 | Habilita site estático                          | `bool`   | `false`  | não         |
| `website_index_document`          | Documento index do site                         | `string` | `index.html` | não     |
| `website_error_document`          | Documento de erro do site                       | `string` | `null`   | não         |
| `notification_sqs`                | Notificações para SQS                           | `any`    | `[]`     | não         |
| `notification_sns`                | Notificações para SNS                           | `any`    | `[]`     | não         |
| `notification_lambda`             | Notificações para Lambda                        | `any`    | `[]`     | não         |
| `tags`                            | Tags adicionais                                 | `map`    | `{}`     | não         |

## Outputs

| Nome                         | Descrição                             |
|------------------------------|---------------------------------------|
| `bucket_id`                  | Nome/ID do bucket                     |
| `bucket_arn`                 | ARN do bucket                         |
| `bucket_domain_name`         | Domínio S3 padrão                     |
| `bucket_regional_domain_name`| Domínio regional                      |
| `bucket_hosted_zone_id`      | Hosted Zone ID (Route53)              |
| `website_endpoint`           | Endpoint do site estático             |
| `website_domain`             | Domínio do site estático              |

---

## Requisitos

- Terraform `>= 1.3.0`
- AWS Provider `>= 5.0`

## Estrutura

```
terraform-s3-module/
├── main.tf          # Recursos principais
├── variables.tf     # Variáveis
├── outputs.tf       # Outputs
├── versions.tf      # Versões requeridas
├── README.md
└── examples/
    └── complete/
        └── main.tf  # Exemplos de uso
```
