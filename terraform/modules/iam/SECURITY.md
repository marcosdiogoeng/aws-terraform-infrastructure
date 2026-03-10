# Guia de Segurança para Access Keys

## ⚠️ IMPORTANTE: Gerenciamento Seguro de Credenciais

As Access Keys geradas por este módulo são sensíveis e devem ser tratadas com cuidado. Nunca commite credenciais no Git!

## Opções para Armazenar Credenciais

### Opção 1: AWS Secrets Manager (Recomendado)

```hcl
# Armazenar access key no Secrets Manager
resource "aws_secretsmanager_secret" "access_key" {
  name        = "app/user/access-key"
  description = "Access keys para app user"
}

resource "aws_secretsmanager_secret_version" "access_key" {
  secret_id = aws_secretsmanager_secret.access_key.id
  secret_string = jsonencode({
    access_key_id     = module.iam_user.access_key_id
    secret_access_key = module.iam_user.secret_access_key
  })
}
```

### Opção 2: AWS Systems Manager Parameter Store

```hcl
# Armazenar access key no Parameter Store
resource "aws_ssm_parameter" "access_key_id" {
  name  = "/app/user/access-key-id"
  type  = "SecureString"
  value = module.iam_user.access_key_id
}

resource "aws_ssm_parameter" "secret_access_key" {
  name  = "/app/user/secret-access-key"
  type  = "SecureString"
  value = module.iam_user.secret_access_key
}
```

### Opção 3: Terraform Output + Script

Após criar o usuário, execute:

```bash
# Extrair credenciais
terraform output -raw backend_user_access_key > access_key.txt
terraform output -raw backend_user_secret_key > secret_key.txt

# IMPORTANTE: Adicione estes arquivos ao .gitignore
echo "access_key.txt" >> .gitignore
echo "secret_key.txt" >> .gitignore

# Use as credenciais e depois DELETE os arquivos
rm access_key.txt secret_key.txt
```

## Best Practices

### 1. Rotação de Chaves

```bash
# Crie um cronjob ou Lambda para rotacionar chaves a cada 90 dias
# Exemplo de rotação manual:
aws iam create-access-key --user-name app-user
# Configure a nova chave na aplicação
# Delete a chave antiga
aws iam delete-access-key --user-name app-user --access-key-id AKIAOLD...
```

### 2. Least Privilege

- Crie policies com o mínimo de permissões necessárias
- Use conditions nas policies quando possível
- Revise permissões regularmente

### 3. Monitoring

```hcl
# CloudWatch Alarm para uso suspeito
resource "aws_cloudwatch_metric_alarm" "suspicious_api_calls" {
  alarm_name          = "suspicious-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "AWS/IAM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alerta para chamadas de API não autorizadas"
}
```

### 4. Prefira IAM Roles quando possível

Para serviços AWS (Lambda, EC2, ECS), sempre use Roles ao invés de Access Keys:

```hcl
# ✅ BOM: Use Role para Lambda
module "lambda_role" {
  source = "./iam-module"
  
  create_role = true
  role_name   = "lambda-role"
  # ...
}

# ❌ EVITE: Criar user com access key para Lambda
module "lambda_user" {
  source = "./iam-module"
  
  create_user       = true
  create_access_key = true  # Não é necessário!
  # ...
}
```

### 5. Use MFA para Usuários Sensíveis

```bash
# Adicionar MFA device ao usuário
aws iam enable-mfa-device \
  --user-name app-user \
  --serial-number arn:aws:iam::123456789012:mfa/app-user \
  --authentication-code-1 123456 \
  --authentication-code-2 789012
```

## Exemplo Completo Seguro

```hcl
# main.tf
module "secure_iam_setup" {
  source = "./iam-module"

  create_user       = true
  user_name         = "app-user"
  create_access_key = true
  
  # ... outras configurações
}

# Armazenar no Secrets Manager
resource "aws_secretsmanager_secret" "credentials" {
  name                    = "app/credentials"
  recovery_window_in_days = 7
  
  tags = {
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    username          = module.secure_iam_setup.user_name
    access_key_id     = module.secure_iam_setup.access_key_id
    secret_access_key = module.secure_iam_setup.secret_access_key
    region            = "us-east-1"
  })
}

# Output apenas o ARN do secret (seguro para commit)
output "credentials_secret_arn" {
  value       = aws_secretsmanager_secret.credentials.arn
  description = "ARN do secret contendo as credenciais"
}
```

## Recuperar Credenciais do Secrets Manager

```bash
# Via AWS CLI
aws secretsmanager get-secret-value \
  --secret-id app/credentials \
  --query SecretString \
  --output text | jq -r '.access_key_id'

# Via Python (boto3)
import boto3
import json

client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='app/credentials')
credentials = json.loads(response['SecretString'])
print(credentials['access_key_id'])
```

## ⚠️ O que NUNCA fazer

1. ❌ Commitar access keys no Git
2. ❌ Compartilhar keys por email/Slack
3. ❌ Usar access keys em código hardcoded
4. ❌ Deixar keys em arquivos .tfvars commitados
5. ❌ Criar usuários com permissões excessivas
6. ❌ Não rotacionar keys regularmente
7. ❌ Não monitorar uso das keys

## Checklist de Segurança

- [ ] Access keys armazenadas em Secrets Manager ou Parameter Store
- [ ] .gitignore configurado corretamente
- [ ] Policies seguem princípio de least privilege
- [ ] Configurado rotação automática de keys
- [ ] CloudWatch alarms para atividades suspeitas
- [ ] MFA habilitado para usuários sensíveis
- [ ] Documentação de acesso atualizada
- [ ] Revisão de permissões agendada
