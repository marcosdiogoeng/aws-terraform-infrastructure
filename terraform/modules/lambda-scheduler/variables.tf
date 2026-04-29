variable "name" {
  description = "Prefix used for naming all resources"
  type        = string
}

variable "source_dir" {
  description = "Path to the directory containing the Lambda source code"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda handler (filename.function_name)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "schedules" {
  description = <<-EOT
    List of EventBridge cron rules that trigger this Lambda.
    Each entry must have:
      - name        : unique suffix for rule/target/permission resources
      - schedule    : EventBridge schedule expression (rate() or cron())
      - input       : JSON string passed as event to the Lambda
      - description : (optional) human-readable description
  EOT
  type = list(object({
    name        = string
    schedule    = string
    input       = string
    description = optional(string, "")
  }))
  default = []
}

variable "iam_statements" {
  description = <<-EOT
    Additional IAM policy statements granted to the Lambda execution role.
    Each entry follows the standard IAM statement structure:
      - effect    : "Allow" or "Deny"
      - actions   : list of IAM actions
      - resources : list of resource ARNs
  EOT
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
