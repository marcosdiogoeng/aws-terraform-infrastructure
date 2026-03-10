# Módulo Terraform — ElastiCache Redis

Módulo reutilizável para provisionar Amazon ElastiCache Redis com boas práticas de segurança, alta disponibilidade e observabilidade.

## Funcionalidades

- **Topologias**: Single Node, Replication Group (Multi-AZ) e Cluster Mode (sharding)
- **Segurança**: Criptografia at-rest e in-transit (TLS), AUTH token, Security Group gerenciado
- **Observabilidade**: CloudWatch Alarms para CPU, memória e conexões
- **Backup**: Snapshots automáticos configuráveis, final snapshot
- **Logs**: Slow logs e Engine logs para CloudWatch Logs ou Kinesis Firehose
- **Configuração**: Parameter group customizável com parâmetros dinâmicos

---

## Estrutura

```
modules/
  elasticache-redis/
    main.tf        # Recursos principais
    variables.tf   # Todas as variáveis com validações e defaults
    outputs.tf     # Outputs úteis (endpoints, ARNs, IDs)
    versions.tf    # Versões do Terraform e providers

examples/
  basic/           # Single node — dev/staging
  cluster-mode/    # Sharding + Multi-AZ — produção
```

---

## Uso Rápido

### Single Node (desenvolvimento)

```hcl
module "redis" {
  source = "./modules/elasticache-redis"

  name       = "myapp-cache"
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  node_type      = "cache.t3.micro"
  engine_version = "7.1"

  allowed_security_group_ids = [aws_security_group.app.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  tags = { Environment = "development" }
}
```

### Cluster Mode (produção)

```hcl
module "redis_prod" {
  source = "./modules/elasticache-redis"

  name       = "prod-cache"
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  node_type      = "cache.r6g.large"
  engine_version = "7.1"

  cluster_mode_enabled    = true
  num_node_groups         = 3      # 3 shards
  replicas_per_node_group = 2      # 2 réplicas por shard
  multi_az_enabled        = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit = 14
  create_cloudwatch_alarms = true
  alarm_actions            = [aws_sns_topic.alerts.arn]

  tags = { Environment = "production" }
}
```

---

## Inputs

| Variável | Descrição | Tipo | Default |
|---|---|---|---|
| `name` | Nome base dos recursos | `string` | — |
| `vpc_id` | ID da VPC | `string` | — |
| `subnet_ids` | Subnets privadas | `list(string)` | — |
| `node_type` | Tipo de instância | `string` | `cache.t3.micro` |
| `engine_version` | Versão do Redis | `string` | `7.1` |
| `num_cache_nodes` | Nós totais (non-cluster) | `number` | `1` |
| `cluster_mode_enabled` | Habilitar sharding | `bool` | `false` |
| `num_node_groups` | Shards (cluster mode) | `number` | `1` |
| `replicas_per_node_group` | Réplicas por shard | `number` | `1` |
| `multi_az_enabled` | Habilitar Multi-AZ | `bool` | `false` |
| `at_rest_encryption_enabled` | Criptografia em repouso | `bool` | `true` |
| `transit_encryption_enabled` | TLS em trânsito | `bool` | `true` |
| `auth_token` | Token de autenticação Redis | `string` | `""` |
| `snapshot_retention_limit` | Dias de retenção de backup | `number` | `7` |
| `create_cloudwatch_alarms` | Criar alarmes CloudWatch | `bool` | `true` |
| `alarm_actions` | ARNs SNS para alarmes | `list(string)` | `[]` |
| `parameters` | Parâmetros customizados | `list(object)` | `[]` |

> Veja `variables.tf` para a lista completa com validações e descrições.

---

## Outputs

| Output | Descrição |
|---|---|
| `primary_endpoint_address` | Endpoint de escrita |
| `reader_endpoint_address` | Endpoint de leitura |
| `cluster_enabled_endpoint` | Endpoint cluster (cluster mode) |
| `primary_connection_string` | `host:port` do endpoint primário |
| `security_group_id` | ID do security group criado |
| `replication_group_id` | ID do replication group |
| `replication_group_arn` | ARN do replication group |

---

## Boas Práticas Implementadas

**Segurança**
- Criptografia at-rest e in-transit habilitadas por padrão
- AUTH token com `sensitive = true`
- Security group com princípio do menor privilégio
- `auth_token` ignorado no `lifecycle` para evitar recriação do cluster

**Alta Disponibilidade**
- `automatic_failover_enabled` ativado automaticamente com Multi-AZ ou Cluster Mode
- Suporte completo a Cluster Mode (sharding horizontal)

**Observabilidade**
- Alarmes CloudWatch para CPU (>75%), memória (<100MB) e conexões (>1000)
- Suporte a slow logs e engine logs para CloudWatch ou Kinesis

**Operações**
- `apply_immediately = false` por padrão (mudanças na janela de manutenção)
- `final_snapshot_identifier` para proteção contra perda de dados
- Parameter group com `create_before_destroy`

---

## Requisitos

| Software | Versão |
|---|---|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |

---

## Notas Importantes

1. **AUTH Token**: Armazene sempre no AWS Secrets Manager, nunca em arquivos `.tfvars` commitados.
2. **Cluster Mode**: Clientes Redis precisam ser cluster-aware (ex: `redis-py-cluster`, `ioredis`).
3. **Endpoints**: Em cluster mode, use `cluster_enabled_endpoint`; caso contrário, use `primary_endpoint_address` (escrita) e `reader_endpoint_address` (leitura).
4. **Família do Parameter Group**: Use `redis7` para versão 7.x e `redis6.x` para versão 6.x.
