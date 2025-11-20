variable "environment" {
  description = "The environment in which the resources are deployed (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "instance_name" {
  description = "The name of the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the EC2 instance will be launched"
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the EC2 instance"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "The subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the EC2 instance"
  type        = list(string)
  default     = []
}

variable "generate_key_pair" {
  description = "Whether to generate a new key pair for the EC2 instance"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "The name of the existing key pair to use for the EC2 instance"
  type        = string
  default     = ""
}

variable "store_key_in_s3" {
  type    = bool
  default = false
}

variable "create_security_group" {
  description = "Whether to create a new security group for the EC2 instance"
  type        = bool
  default     = false
}

variable "security_group_rules" {
  description = "A map defining ingress and egress rules for the security group"
  type = object({
    ingress = optional(list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = list(string)
      security_groups = optional(list(string))
    })), [])
    egress = optional(list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = list(string)
      security_groups = optional(list(string))
      })), [
      {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ])
  })
  default = {
    ingress = []
    egress = [
      {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}

variable "associate_eip" {
  description = "EIP instance associate"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "s3_key_name" {
  description = "Key name for the S3 object"
  type        = string
}

variable "attach_ssm_role" {
  description = "SSM role"
  type        = bool
  default     = false
}

variable "user_data" {
  description = ""
  type        = string
  default     = null
}

variable "user_data_base64" {
  type    = string
  default = null
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for the EC2 instance"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "root_block_device" {
  type = object({
    volume_type           = string
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool)
  })
  default = null
}

variable "ebs_block_devices" {
  type = list(object({
    device_name           = string
    volume_type           = string
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool)
  }))
  default = []
}

