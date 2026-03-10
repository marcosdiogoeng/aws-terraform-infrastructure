# ==============================================================================
# terraform-aws-ecs-service – Variables
# ==============================================================================

# ── Identificação ──────────────────────────────────────────────────────────────
variable "name" {
  description = "Nome do serviço ECS"
  type        = string
}

variable "cluster_arn" {
  description = "ARN do cluster ECS onde o serviço será criado"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster ECS (usado para nomear log groups e autoscaling)"
  type        = string
}

# ── Task Definition ────────────────────────────────────────────────────────────
variable "task_family" {
  description = "Família da task definition. Padrão: nome do serviço"
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "CPU units da task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memória da task em MiB"
  type        = string
  default     = "512"
}

variable "network_mode" {
  description = "Modo de rede da task definition (awsvpc | bridge | host | none)"
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Lista de compatibilidades da task (FARGATE | EC2)"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "operating_system_family" {
  description = "Família de SO (LINUX | WINDOWS_SERVER_2019_FULL | etc)"
  type        = string
  default     = "LINUX"
}

variable "cpu_architecture" {
  description = "Arquitetura da CPU (X86_64 | ARM64)"
  type        = string
  default     = "X86_64"
}

variable "container_definitions" {
  description = <<-EOT
    Lista de definições de containers. Cada item é um objeto com os campos abaixo.
    Campos obrigatórios: name, image.

    Campos suportados:
      name                    string   – nome do container
      image                   string   – URI da imagem
      essential               bool     – padrão: true
      cpu                     number   – reserva de CPU units
      memory                  number   – limite de memória (MiB)
      memory_reservation      number   – reserva soft de memória (MiB)
      port_mappings           list     – [{container_port, host_port?, protocol?, name?}]
      environment             map      – variáveis de ambiente como map(string)
      secrets                 list     – [{name, value_from}] para SSM/Secrets Manager
      log_configuration       object   – override do log driver (padrão: awslogs automático)
      command                 list     – override de CMD
      entry_point             list     – override de ENTRYPOINT
      working_directory       string
      readonly_root_filesystem bool    – padrão: false
      mount_points            list     – [{source_volume, container_path, read_only?}]
      volumes_from            list     – [{source_container, read_only?}]
      health_check            object   – {command, interval, timeout, retries, startPeriod}
      depends_on              list     – [{container_name, condition}]
      linux_parameters        object   – configurações Linux extras
      ulimits                 list     – [{name, softLimit, hardLimit}]
      user                    string   – UID:GID
      docker_labels           map      – labels Docker
      stop_timeout            number   – segundos para dreno do container (máx 120)
      start_timeout           number   – segundos de tolerância para dependsOn
      repository_credentials  object   – {credentialsParameter} para registry privado
      extra_hosts             list     – [{hostname, ipAddress}]
      system_controls         list     – [{namespace, value}]
  EOT
  type        = any
}

variable "volumes" {
  description = <<-EOT
    Lista de volumes para a task definition.

    Tipos suportados:
      - EFS: { name, efs = { file_system_id, root_directory?, access_point_id?, iam? } }
      - Docker: { name, docker = { scope?, driver?, driver_opts?, labels? } }
      - Bind mount (tmpfs): { name }
  EOT
  type        = any
  default     = []
}

# ── IAM ────────────────────────────────────────────────────────────────────────
variable "create_execution_role" {
  description = "Cria a IAM execution role automaticamente"
  type        = bool
  default     = true
}

variable "execution_role_name" {
  description = "Nome da execution role (opcional, padrão: <name>-ecs-execution)"
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "ARN de uma execution role existente (usado quando create_execution_role = false)"
  type        = string
  default     = null
}

variable "secret_arns" {
  description = "ARNs de segredos do SSM/Secrets Manager que a execution role pode ler. Vazio = '*'"
  type        = list(string)
  default     = []
}

variable "create_task_role" {
  description = "Cria a IAM task role automaticamente"
  type        = bool
  default     = true
}

variable "task_role_name" {
  description = "Nome da task role (opcional, padrão: <name>-ecs-task)"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN de uma task role existente (usado quando create_task_role = false)"
  type        = string
  default     = null
}

variable "task_role_policy_arns" {
  description = "Lista de ARNs de managed policies a anexar à task role"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policy" {
  description = "Política inline JSON para a task role (adiciona permissões customizadas)"
  type        = string
  default     = null
}

# ── Serviço ECS ────────────────────────────────────────────────────────────────
variable "desired_count" {
  description = "Número de tasks desejadas"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "Tipo de lançamento (FARGATE | EC2). Ignorado se capacity_provider_strategy estiver definido"
  type        = string
  default     = "FARGATE"
}

variable "platform_version" {
  description = "Versão da plataforma Fargate (ex: LATEST, 1.4.0)"
  type        = string
  default     = "LATEST"
}

variable "capacity_provider_strategy" {
  description = <<-EOT
    Estratégia de capacity providers. Quando definida, sobrescreve launch_type.
    Ex: [{ capacity_provider = "FARGATE_SPOT", weight = 3 }, { capacity_provider = "FARGATE", weight = 1, base = 1 }]
  EOT
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = []
}

variable "deployment_minimum_healthy_percent" {
  description = "% mínima de tasks saudáveis durante o deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "% máxima de tasks durante o deployment"
  type        = number
  default     = 200
}

variable "deployment_circuit_breaker_enable" {
  description = "Habilita o circuit breaker de deployment"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Faz rollback automático quando o circuit breaker é ativado"
  type        = bool
  default     = true
}

variable "deployment_controller_type" {
  description = "Tipo de deployment controller (ECS | CODE_DEPLOY | EXTERNAL)"
  type        = string
  default     = "ECS"
}

variable "enable_execute_command" {
  description = "Habilita ECS Exec (necessário para acesso interativo ao container)"
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "Força novo deployment ao executar apply"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Aguarda o serviço atingir steady state antes de finalizar o apply"
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Propaga tags do serviço/task definition para as tasks (SERVICE | TASK_DEFINITION | NONE)"
  type        = string
  default     = "SERVICE"
}

variable "health_check_grace_period_seconds" {
  description = "Segundos para ignorar falhas de health check após o início de uma nova task"
  type        = number
  default     = 60
}

variable "service_connect_configuration" {
  description = "Configuração do ECS Service Connect para service mesh nativo"
  type        = any
  default     = null
}

# ── Rede ───────────────────────────────────────────────────────────────────────
variable "subnets" {
  description = "Subnets onde as tasks serão executadas (preferencialmente privadas)"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups das tasks"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Atribui IP público às tasks (necessário em subnets públicas sem NAT)"
  type        = bool
  default     = false
}

# ── Integração com ALB ─────────────────────────────────────────────────────────
variable "target_group_arn" {
  description = "ARN do target group do ALB onde este serviço deve ser registrado. Null = sem ALB"
  type        = string
  default     = null
}

variable "load_balancer_container_name" {
  description = "Nome do container que receberá tráfego do ALB"
  type        = string
  default     = null
}

variable "load_balancer_container_port" {
  description = "Porta do container que receberá tráfego do ALB"
  type        = number
  default     = null
}

# ── Autoscaling ────────────────────────────────────────────────────────────────
variable "autoscaling_enabled" {
  description = "Habilita Application Auto Scaling para o serviço"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Número mínimo de tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Número máximo de tasks"
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "% de CPU alvo para escalar. Null = desabilitado"
  type        = number
  default     = null
}

variable "autoscaling_memory_target" {
  description = "% de Memória alvo para escalar. Null = desabilitado"
  type        = number
  default     = null
}

variable "autoscaling_alb_requests_target" {
  description = "Request count por target alvo para escalar. Null = desabilitado. Requer target_group_arn, alb_arn_suffix e target_group_arn_suffix"
  type        = number
  default     = null
}

variable "autoscaling_scale_in_cooldown" {
  description = "Segundos de cooldown para scale in"
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Segundos de cooldown para scale out"
  type        = number
  default     = 60
}

variable "alb_arn_suffix" {
  description = "arn_suffix do ALB (saída do módulo terraform-aws-alb). Necessário para autoscaling por ALB requests"
  type        = string
  default     = null
}

variable "target_group_arn_suffix" {
  description = "arn_suffix do target group (saída do módulo terraform-aws-alb). Necessário para autoscaling por ALB requests"
  type        = string
  default     = null
}

# ── Logs ───────────────────────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "Retenção dos logs do CloudWatch em dias"
  type        = number
  default     = 2
}

variable "cloudwatch_kms_key_arn" {
  description = "ARN da KMS key para criptografar os logs do CloudWatch"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
