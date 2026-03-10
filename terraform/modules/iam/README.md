# Módulo IAM Genérico para AWS

Este módulo Terraform permite criar e gerenciar recursos IAM na AWS de forma modular e reutilizável.

## Recursos Suportados

- **IAM User**: Criação de usuários IAM
- **IAM Policy**: Criação de políticas customizadas (via arquivo JSON ou inline)
- **IAM Role**: Criação de roles IAM
- **IAM Access Key**: Criação de chaves de acesso para usuários

## Uso

### Exemplo 1: Criar usuário com policy customizada via arquivo JSON

```hcl
module "iam_user_s3" {
  source = "./iam-module"

  # User
  create_user = true
  user_name   = "app-s3-user"

  # Custom Policy via arquivo
  create_custom_policy         = true
  policy_name                  = "S3ReadOnlyPolicy"
  policy_description           = "Policy para leitura de buckets S3"
  policy_json_file             = "./policies/s3-read-only.json"
  attach_custom_policy_to_user = true

  # Access Key
  create_access_key = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "user_access_key_id" {
  value     = module.iam_user_s3.access_key_id
  sensitive = true
}

output "user_secret_key" {
  value     = module.iam_user_s3.secret_access_key
  sensitive = true
}
```

### Exemplo 2: Criar role com policy e assume role policy

```hcl
module "iam_role_lambda" {
  source = "./iam-module"

  # Role
  create_role              = true
  role_name                = "lambda-execution-role"
  role_description         = "Role para execução de funções Lambda"
  assume_role_policy_file  = "./policies/lambda-assume-role.json"
  role_max_session_duration = 3600

  # Custom Policy
  create_custom_policy         = true
  policy_name                  = "LambdaDynamoDBPolicy"
  policy_json_file             = "./policies/lambda-dynamodb.json"
  attach_custom_policy_to_role = true

  # Managed Policies
  role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Environment = "production"
    Service     = "Lambda"
  }
}
```

### Exemplo 3: Criar usuário com múltiplas managed policies

```hcl
module "iam_user_dev" {
  source = "./iam-module"

  # User
  create_user = true
  user_name   = "developer-user"

  # Managed Policies AWS
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  ]

  # Access Key
  create_access_key = true

  tags = {
    Team = "Development"
  }
}
```

### Exemplo 4: Apenas criar policy customizada (sem user ou role)

```hcl
module "iam_policy_only" {
  source = "./iam-module"

  create_custom_policy = true
  policy_name          = "CustomS3Policy"
  policy_description   = "Policy customizada para S3"
  policy_json_file     = "./policies/s3-custom.json"

  tags = {
    Type = "CustomPolicy"
  }
}
```

## Estrutura de Arquivos de Policy

### Exemplo de Policy JSON (s3-read-only.json)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/*",
        "arn:aws:s3:::my-bucket"
      ]
    }
  ]
}
```

### Exemplo de Assume Role Policy (lambda-assume-role.json)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Variáveis

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|-------------|
| `create_user` | Se deve criar um usuário IAM | `bool` | `false` | Não |
| `user_name` | Nome do usuário IAM | `string` | `""` | Se create_user = true |
| `create_custom_policy` | Se deve criar uma policy customizada | `bool` | `false` | Não |
| `policy_name` | Nome da policy IAM | `string` | `""` | Se create_custom_policy = true |
| `policy_json_file` | Caminho para o arquivo JSON com a policy | `string` | `""` | Se create_custom_policy = true |
| `policy_json_content` | Conteúdo JSON da policy (alternativa ao arquivo) | `string` | `""` | Não |
| `attach_custom_policy_to_user` | Se deve anexar a policy ao usuário | `bool` | `false` | Não |
| `managed_policy_arns` | Lista de ARNs de policies AWS gerenciadas para o usuário | `list(string)` | `[]` | Não |
| `create_role` | Se deve criar uma role IAM | `bool` | `false` | Não |
| `role_name` | Nome da role IAM | `string` | `""` | Se create_role = true |
| `assume_role_policy_json` | JSON da assume role policy (inline) | `string` | `""` | Se create_role = true |
| `assume_role_policy_file` | Caminho para o arquivo JSON com a assume role policy | `string` | `""` | Se create_role = true |
| `attach_custom_policy_to_role` | Se deve anexar a policy à role | `bool` | `false` | Não |
| `role_managed_policy_arns` | Lista de ARNs de policies AWS gerenciadas para a role | `list(string)` | `[]` | Não |
| `create_access_key` | Se deve criar access key para o usuário | `bool` | `false` | Não |
| `tags` | Tags comuns para todos os recursos | `map(string)` | `{}` | Não |

## Outputs

| Nome | Descrição | Sensível |
|------|-----------|----------|
| `user_name` | Nome do usuário IAM criado | Não |
| `user_arn` | ARN do usuário IAM criado | Não |
| `policy_name` | Nome da policy IAM criada | Não |
| `policy_arn` | ARN da policy IAM criada | Não |
| `role_name` | Nome da role IAM criada | Não |
| `role_arn` | ARN da role IAM criada | Não |
| `access_key_id` | Access Key ID do usuário | Sim |
| `secret_access_key` | Secret Access Key do usuário | Sim |

## Notas Importantes

1. **Segurança das Access Keys**: As chaves de acesso são marcadas como sensíveis. Recomenda-se armazená-las em um gerenciador de secrets (AWS Secrets Manager, Parameter Store, etc.).

2. **Arquivos de Policy**: Certifique-se de que os arquivos JSON das policies estejam no formato correto e sejam válidos.

3. **Permissões**: Você precisa ter as permissões apropriadas no IAM para criar usuários, policies, roles e access keys.

4. **Best Practices**:
   - Use o princípio do menor privilégio ao criar policies
   - Rotacione as access keys regularmente
   - Use roles ao invés de usuários sempre que possível
   - Adicione MFA para usuários com permissões elevadas

## Exemplo Completo

```hcl
module "complete_iam_setup" {
  source = "./iam-module"

  # User
  create_user = true
  user_name   = "app-backend-user"
  user_path   = "/applications/"

  # Custom Policy
  create_custom_policy         = true
  policy_name                  = "BackendAppPolicy"
  policy_description           = "Policy para aplicação backend"
  policy_json_file             = "./policies/backend-app-policy.json"
  attach_custom_policy_to_user = true

  # Managed Policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  # Access Key
  create_access_key = true

  tags = {
    Application = "Backend"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 4.0
