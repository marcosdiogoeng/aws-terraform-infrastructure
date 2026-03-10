# terraform-aws-ecs-service

Módulo Terraform para criar um **ECS Service** completo: Task Definition, IAM Roles, CloudWatch Logs e Application Auto Scaling. Integra-se com o módulo `terraform-aws-alb` via `target_group_arn`.

## Recursos criados

- `aws_ecs_task_definition`
- `aws_ecs_service` (com circuit breaker + deploy controller)
- `aws_iam_role` (execution role + task role)
- `aws_cloudwatch_log_group` por container
- `aws_appautoscaling_target` + policies de CPU/Memória/ALB *(opcionais)*

## Uso

```hcl
module "service_api" {
  source = "git::https://github.com/sua-org/terraform-aws-ecs-service.git?ref=v1.0.0"

  name         = "api"
  cluster_arn  = module.cluster.cluster_arn
  cluster_name = module.cluster.cluster_name

  task_cpu    = "1024"
  task_memory = "2048"

  container_definitions = [
    {
      name  = "api"
      image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
      port_mappings = [{ container_port = 8080 }]
      environment = { PORT = "8080" }
      secrets = [
        { name = "DB_URL", value_from = "/prod/api/db-url" }
      ]
    }
  ]

  subnets         = var.private_subnets
  security_groups = [aws_security_group.ecs_tasks.id]

  # Liga ao ALB compartilhado
  target_group_arn             = module.alb.target_group_arns["api"]
  load_balancer_container_name = "api"
  load_balancer_container_port = 8080

  # Autoscaling
  autoscaling_enabled       = true
  autoscaling_min_capacity  = 2
  autoscaling_max_capacity  = 20
  autoscaling_cpu_target    = 65

  tags = { Environment = "production" }
}
```

## Inputs principais

### Identificação
| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `name` | `string` | – | Nome do serviço |
| `cluster_arn` | `string` | – | ARN do cluster ECS |
| `cluster_name` | `string` | – | Nome do cluster (para log groups e autoscaling) |

### Task Definition
| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `task_cpu` | `string` | `"256"` | CPU units |
| `task_memory` | `string` | `"512"` | Memória em MiB |
| `container_definitions` | `any` | – | Lista de containers (obrigatório) |
| `volumes` | `any` | `[]` | Volumes (EFS, Docker, bind) |
| `cpu_architecture` | `string` | `"X86_64"` | `X86_64` ou `ARM64` |

### IAM
| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `create_execution_role` | `bool` | `true` | Cria execution role |
| `execution_role_arn` | `string` | `null` | ARN de role existente |
| `create_task_role` | `bool` | `true` | Cria task role |
| `task_role_policy_arns` | `list(string)` | `[]` | Managed policies extras |
| `task_role_inline_policy` | `string` | `null` | Policy inline JSON |

### Integração com ALB
| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `target_group_arn` | `string` | `null` | ARN do TG do ALB. Null = sem ALB |
| `load_balancer_container_name` | `string` | `null` | Container que recebe tráfego |
| `load_balancer_container_port` | `number` | `null` | Porta do container |

### Autoscaling
| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `autoscaling_enabled` | `bool` | `false` | Habilita autoscaling |
| `autoscaling_min_capacity` | `number` | `1` | Mínimo de tasks |
| `autoscaling_max_capacity` | `number` | `10` | Máximo de tasks |
| `autoscaling_cpu_target` | `number` | `null` | % CPU alvo |
| `autoscaling_memory_target` | `number` | `null` | % Memória alvo |
| `autoscaling_alb_requests_target` | `number` | `null` | Req/target alvo (requer `alb_arn_suffix` e `target_group_arn_suffix`) |

## Outputs

| Output | Descrição |
|--------|-----------|
| `service_id` | ID do serviço ECS |
| `service_name` | Nome do serviço |
| `task_definition_arn` | ARN completo da task definition |
| `task_role_arn` | ARN da task role |
| `execution_role_arn` | ARN da execution role |
| `log_group_names` | Mapa `container → log group` |
