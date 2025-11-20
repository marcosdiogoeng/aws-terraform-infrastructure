variable "environment" {}
variable "tags" {
  type        = map(string)
  description = "Tags to be added, making reference to locals.tf"
}

variable "cluster_name" {
  description = "Name of the AWS EKS Cluster"
}

variable "oidc" {
  type        = string
  description = "HTTPS URL from the OIDC provider associated with the EKS cluster"
}

variable "create_helm_release" {
  type    = bool
  default = false
}

variable "release_name" {
  type    = string
  default = ""
}

variable "chart_repository" {
  type    = string
  default = ""
}

variable "chart_name" {
  type    = string
  default = ""
}

variable "chart_version" {
  type    = string
  default = ""
}

variable "create_namespace" {
  type    = bool
  default = false
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "create_service_account" {
  type    = bool
  default = false
}

variable "service_account_name" {
  type    = string
  default = ""
}

variable "helm_values" {
  type    = map(string)
  default = {}
}

variable "create_iam_role" {
  type    = bool
  default = false
}

variable "iam_role_name" {
  type    = string
  default = ""
}

variable "iam_policy_statements" {
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "iam_policy_json_file" {
  type    = string
  default = ""
}

variable "iam_policy_arns" {
  type    = list(string)
  default = []
}

variable "created_managed_policies" {
  type    = bool
  default = false
}

variable "managed_role" {
  type    = string
  default = ""
}