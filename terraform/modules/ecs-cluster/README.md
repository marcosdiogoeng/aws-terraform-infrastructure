# terraform-aws-ecs-cluster

Módulo Terraform para criar um **ECS Cluster** com Container Insights, Capacity Providers e opcionalmente KMS e auditoria de ECS Exec.

## Recursos criados

- `aws_ecs_cluster`
- `aws_ecs_cluster_capacity_providers`
- `aws_kms_key` + `aws_kms_alias` *(opcional)*
- `aws_cloudwatch_log_group` para ECS Exec *(opcional)*

## Uso

```hcl
module "cluster" {
  source = "git::https://github.com/sua-org/terraform-aws-ecs-cluster.git?ref=v1.0.0"

  name               = "producao"
  container_insights = true
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = [
    { capacity_provider = "FARGATE",      weight = 1, base = 1 },
    { capacity_provider = "FARGATE_SPOT", weight = 4, base = 0 },
  ]

  tags = { Environment = "production" }
}

# Nos módulos de serviço:
# cluster_arn  = module.cluster.cluster_arn
# cluster_name = module.cluster.cluster_name
```

## Inputs

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `name` | `string` | – | Nome do cluster |
| `container_insights` | `bool` | `true` | Habilita Container Insights |
| `capacity_providers` | `list(string)` | `["FARGATE","FARGATE_SPOT"]` | Providers disponíveis |
| `default_capacity_provider_strategy` | `list(object)` | FARGATE+SPOT | Estratégia padrão |
| `create_kms_key` | `bool` | `false` | Cria KMS key dedicada |
| `create_exec_log_group` | `bool` | `false` | CW Log Group para ECS Exec |

## Outputs

| Output | Descrição |
|--------|-----------|
| `cluster_arn` | ARN do cluster |
| `cluster_name` | Nome do cluster |
| `cluster_id` | ID do cluster |
| `kms_key_arn` | ARN da KMS key (null se não criada) |
