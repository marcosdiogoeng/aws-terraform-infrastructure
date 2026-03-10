# Terraform Module — AWS ECR

Módulo Terraform reutilizável para criação e gerenciamento de repositórios **Amazon ECR** com suporte a lifecycle policies, criptografia KMS, IAM policies e replicação entre regiões.

---

## Recursos criados

| Recurso | Descrição |
|---|---|
| `aws_ecr_repository` | Repositório ECR principal |
| `aws_ecr_lifecycle_policy` | Lifecycle policy (padrão ou customizada) |
| `aws_ecr_repository_policy` | IAM policy do repositório (opcional) |
| `aws_ecr_replication_configuration` | Replicação entre regiões (opcional) |

---

## Uso básico

```hcl
module "ecr" {
  source = "git::https://github.com/sua-org/terraform-ecr-module.git"

  repository_name = "minha-app"

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}

output "ecr_url" {
  value = module.ecr.repository_url
}
```

---

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|---|---|---|---|---|
| `repository_name` | Nome do repositório ECR | `string` | — | ✅ |
| `image_tag_mutability` | `MUTABLE` ou `IMMUTABLE` | `string` | `"IMMUTABLE"` | ❌ |
| `scan_on_push` | Escanear imagens ao fazer push | `bool` | `true` | ❌ |
| `encryption_type` | `AES256` ou `KMS` | `string` | `"AES256"` | ❌ |
| `kms_key_arn` | ARN da chave KMS (quando `KMS`) | `string` | `null` | ❌ |
| `force_delete` | Deletar mesmo com imagens | `bool` | `false` | ❌ |
| `enable_default_lifecycle_policy` | Ativa lifecycle policy padrão | `bool` | `true` | ❌ |
| `lifecycle_policy` | Lifecycle policy customizada (JSON) | `string` | `null` | ❌ |
| `max_image_count` | Máximo de imagens tagged a manter | `number` | `10` | ❌ |
| `untagged_image_days` | Dias para expirar imagens sem tag | `number` | `7` | ❌ |
| `lifecycle_tag_prefixes` | Prefixos de tag para retenção | `list(string)` | `["v"]` | ❌ |
| `repository_policy` | IAM policy do repositório (JSON) | `string` | `null` | ❌ |
| `replication_destinations` | Destinos de replicação | `list(object)` | `[]` | ❌ |
| `replication_filters` | Filtros de replicação | `list(object)` | `[]` | ❌ |
| `tags` | Tags aplicadas a todos os recursos | `map(string)` | `{}` | ❌ |

---

## Outputs

| Nome | Descrição |
|---|---|
| `repository_arn` | ARN do repositório |
| `repository_url` | URL para `docker push/pull` |
| `repository_name` | Nome do repositório |
| `registry_id` | Account ID da AWS (registry ID) |

---

## Exemplos

### Criptografia com KMS + acesso cross-account

```hcl
module "ecr" {
  source = "../terraform-ecr-module"

  repository_name = "app-secure"
  encryption_type = "KMS"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CrossAccount"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::987654321098:root" }
      Action = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
    }]
  })

  tags = { Environment = "production" }
}
```

### Replicação entre regiões

```hcl
module "ecr" {
  source = "../terraform-ecr-module"

  repository_name = "app-global"

  replication_destinations = [
    { region = "eu-west-1", registry_id = "123456789012" },
    { region = "ap-southeast-1", registry_id = "123456789012" }
  ]
}
```

### Lifecycle policy totalmente customizada

```hcl
module "ecr" {
  source = "../terraform-ecr-module"

  repository_name                 = "app-custom"
  enable_default_lifecycle_policy = false

  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Manter apenas 5 imagens de prod"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["prod-"]
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = { type = "expire" }
    }]
  })
}
```

---

## Requisitos

| Nome | Versão |
|---|---|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |

---

## Estrutura do módulo

```
terraform-ecr-module/
├── main.tf          # Recursos principais
├── variables.tf     # Variáveis de entrada
├── outputs.tf       # Outputs
├── versions.tf      # Requisitos de versão
├── examples/
│   └── main.tf      # Exemplos de uso
└── README.md
```
