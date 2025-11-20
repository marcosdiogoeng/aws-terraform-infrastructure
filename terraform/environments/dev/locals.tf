locals {

  tags = {
    Department  = "devops"
    Environment = var.environment
    ManagedBy   = "terraform"

  }
}