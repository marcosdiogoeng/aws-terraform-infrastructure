# Terraform AWS RDS Module

Módulo Terraform reutilizável para provisionamento de instâncias Amazon RDS com boas práticas de segurança, monitoramento e alta disponibilidade.

## Recursos criados

| Recurso | Descrição |
|---|---|
| `aws_db_instance` | Instância principal do RDS |
| `aws_db_instance` (réplicas) | Read replicas opcionais |
| `aws_db_subnet_group` | Subnet group para o RDS |
| `aws_security_group` | Security group gerenciado |
| `aws_db_parameter_group` | Grupo de parâmetros customizável |
| `aws_db_option_group` | Grupo de opções (Oracle/SQL Server) |
| `aws_iam_role` | Role para Enhanced Monitoring |
| `aws_cloudwatch_log_group` | Log groups para logs exportados |
| `aws_secretsmanager_secret` | Senha do master no Secrets Manager |

## Uso

### PostgreSQL — Produção

```hcl
module "rds" {
  source = "git::https://github.com/your-org/terraform-aws-rds.git"

  identifier = "my-app-postgres-prod"

  engine         = "postgres"
  engine_version = "16.2"
  instance_class = "db.t3.medium"

  allocated_storage     = 100
  max_allocated_storage = 500

  db_name  = "myapp"
  username = "myapp_admin"

  vpc_id     = "vpc-xxxxxxxx"
  subnet_ids = ["subnet-aaaa", "subnet-bbbb", "subnet-cccc"]

  allowed_cidr_blocks = ["10.0.0.0/16"]

  multi_az                = true
  backup_retention_period = 14
  deletion_protection     = true

  monitoring_interval          = 60
  performance_insights_enabled = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### MySQL — Desenvolvimento

```hcl
module "rds_dev" {
  source = "git::https://github.com/your-org/terraform-aws-rds.git"

  identifier     = "my-app-mysql-dev"
  engine         = "mysql"
  engine_version = "8.0.36"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  db_name           = "myapp"
  port              = 3306

  vpc_id     = "vpc-xxxxxxxx"
  subnet_ids = ["subnet-aaaa", "subnet-bbbb"]

  allowed_cidr_blocks     = ["10.0.0.0/16"]
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 3

  tags = { Environment = "development" }
}
```

## Estrutura

```
terraform-rds-module/
├── main.tf          # Recursos principais
├── variables.tf     # Todas as variáveis
├── outputs.tf       # Outputs do módulo
├── versions.tf      # Requisitos de versão
└── examples/
    └── complete/
        └── main.tf  # Exemplos de uso
```

## Inputs

### Obrigatórios

| Nome | Tipo | Descrição |
|------|------|-----------|
| `identifier` | `string` | Nome identificador da instância RDS |
| `engine` | `string` | Engine do banco (`postgres`, `mysql`, `mariadb`, etc.) |
| `engine_version` | `string` | Versão do engine |
| `instance_class` | `string` | Tipo de instância (ex: `db.t3.medium`) |
| `vpc_id` | `string` | ID da VPC |
| `subnet_ids` | `list(string)` | IDs das subnets |

### Opcionais (principais)

| Nome | Padrão | Descrição |
|------|--------|-----------|
| `allocated_storage` | `20` | Armazenamento inicial em GB |
| `max_allocated_storage` | `0` | Limite para autoscaling (0 = desabilitado) |
| `storage_type` | `"gp3"` | Tipo de storage |
| `storage_encrypted` | `true` | Habilita criptografia |
| `multi_az` | `false` | Alta disponibilidade Multi-AZ |
| `backup_retention_period` | `7` | Dias para retenção de backups |
| `deletion_protection` | `true` | Proteção contra deleção |
| `monitoring_interval` | `0` | Intervalo para Enhanced Monitoring (0 = off) |
| `performance_insights_enabled` | `false` | Habilita Performance Insights |
| `replica_count` | `0` | Número de read replicas |

## Outputs

| Nome | Descrição |
|------|-----------|
| `db_instance_endpoint` | Endpoint de conexão (host:port) |
| `db_instance_address` | Endereço do host |
| `db_instance_port` | Porta |
| `db_instance_name` | Nome do banco de dados |
| `db_instance_username` | Usuário master (sensitive) |
| `db_security_group_id` | ID do Security Group criado |
| `db_master_password_secret_arn` | ARN do secret no Secrets Manager |
| `db_replica_endpoints` | Lista de endpoints das réplicas |

## Boas práticas incluídas

- ✅ Senha gerada automaticamente e armazenada no **Secrets Manager**
- ✅ Criptografia de storage habilitada por padrão
- ✅ **Deletion protection** habilitada por padrão
- ✅ Final snapshot criado ao destruir (configurável)
- ✅ Security Group com regras mínimas de acesso
- ✅ IAM Role para Enhanced Monitoring criada automaticamente
- ✅ Log groups no CloudWatch com retenção configurável
- ✅ Suporte a **Multi-AZ** e **Read Replicas**
- ✅ Autoscaling de storage com `max_allocated_storage`
- ✅ `ignore_changes` na senha para evitar drift após rotação

## Requisitos

| Nome | Versão |
|------|--------|
| terraform | >= 1.3.0 |
| aws | >= 5.0 |
| random | >= 3.0 |

## Engines suportadas

- `postgres` (padrão porta: 5432)
- `mysql` (padrão porta: 3306)
- `mariadb` (padrão porta: 3306)
- `oracle-se2`, `oracle-ee` (requer `license_model`)
- `sqlserver-ex`, `sqlserver-web`, `sqlserver-se`, `sqlserver-ee`
