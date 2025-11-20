variable "aws_region" {
  type        = string
  description = "AWS region to deploy the resources"
  default     = "us-east-1"

}

variable "cidr_block" {
  type        = string
  description = "Networking CIDR block to be used for the VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  type        = string
  description = "value of the environment"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "eks"
} 