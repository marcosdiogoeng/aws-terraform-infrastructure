# ==============================================================================
# ECR Repository
# ==============================================================================

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  force_delete = var.force_delete

  tags = merge(
    var.tags,
    { Name = var.repository_name }
  )
}

# ==============================================================================
# Lifecycle Policy
# ==============================================================================

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "default" {
  count      = var.lifecycle_policy == null && var.enable_default_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images tagged"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = var.lifecycle_tag_prefixes
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ==============================================================================
# Repository Policy (cross-account / cross-service access)
# ==============================================================================

resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy
}

# ==============================================================================
# Replication Configuration (optional)
# ==============================================================================

resource "aws_ecr_replication_configuration" "this" {
  count = length(var.replication_destinations) > 0 ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_destinations
        content {
          region      = destination.value.region
          registry_id = destination.value.registry_id
        }
      }

      dynamic "repository_filter" {
        for_each = var.replication_filters
        content {
          filter      = repository_filter.value.filter
          filter_type = repository_filter.value.filter_type
        }
      }
    }
  }
}
