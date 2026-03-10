# ============================================================
# CloudFront Distribution — Módulo Reutilizável
# ============================================================

locals {
  s3_origin_ids  = { for o in var.s3_origins : o.origin_id => o }
  custom_origin_ids = { for o in var.custom_origins : o.origin_id => o }
}

# ---------- Origin Access Control (OAC) para S3 ----------
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = { for o in var.s3_origins : o.origin_id => o if lookup(o, "create_oac", true) }

  name                              = "${var.distribution_name}-${each.key}-oac"
  description                       = "OAC para ${var.distribution_name} - ${each.key}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------- Distribuição CloudFront ----------
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = var.aliases
  price_class         = var.price_class
  http_version        = var.http_version
  web_acl_id          = var.web_acl_id

  # ---------- Origins S3 ----------
  dynamic "origin" {
    for_each = local.s3_origin_ids
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = lookup(origin.value, "origin_path", null)
      connection_attempts      = lookup(origin.value, "connection_attempts", 3)
      connection_timeout       = lookup(origin.value, "connection_timeout", 10)
      origin_access_control_id = lookup(origin.value, "create_oac", true) ? aws_cloudfront_origin_access_control.this[origin.key].id : lookup(origin.value, "oac_id", null)

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  # ---------- Origins Customizados (ALB, API GW, HTTP) ----------
  dynamic "origin" {
    for_each = local.custom_origin_ids
    content {
      domain_name         = origin.value.domain_name
      origin_id           = origin.value.origin_id
      origin_path         = lookup(origin.value, "origin_path", null)
      connection_attempts = lookup(origin.value, "connection_attempts", 3)
      connection_timeout  = lookup(origin.value, "connection_timeout", 10)

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_headers", [])
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      custom_origin_config {
        http_port                = lookup(origin.value, "http_port", 80)
        https_port               = lookup(origin.value, "https_port", 443)
        origin_protocol_policy   = lookup(origin.value, "origin_protocol_policy", "https-only")
        origin_ssl_protocols     = lookup(origin.value, "origin_ssl_protocols", ["TLSv1.2"])
        origin_read_timeout      = lookup(origin.value, "origin_read_timeout", 30)
        origin_keepalive_timeout = lookup(origin.value, "origin_keepalive_timeout", 5)
      }
    }
  }

  # ---------- Grupos de Origem (Failover) ----------
  dynamic "origin_group" {
    for_each = var.origin_groups
    content {
      origin_id = origin_group.value.origin_id

      failover_criteria {
        status_codes = origin_group.value.status_codes
      }

      member {
        origin_id = origin_group.value.primary_origin_id
      }

      member {
        origin_id = origin_group.value.failover_origin_id
      }
    }
  }

  # ---------- Comportamento Padrão ----------
  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = lookup(var.default_cache_behavior, "viewer_protocol_policy", "redirect-to-https")
    allowed_methods        = lookup(var.default_cache_behavior, "allowed_methods", ["GET", "HEAD"])
    cached_methods         = lookup(var.default_cache_behavior, "cached_methods", ["GET", "HEAD"])
    compress               = lookup(var.default_cache_behavior, "compress", true)

    cache_policy_id            = lookup(var.default_cache_behavior, "cache_policy_id", null)
    origin_request_policy_id   = lookup(var.default_cache_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(var.default_cache_behavior, "response_headers_policy_id", null)

    # TTL manual (apenas quando NÃO usa cache_policy_id)
    dynamic "forwarded_values" {
      for_each = lookup(var.default_cache_behavior, "cache_policy_id", null) == null ? [1] : []
      content {
        query_string = lookup(var.default_cache_behavior, "forward_query_string", false)
        headers      = lookup(var.default_cache_behavior, "forward_headers", [])

        cookies {
          forward = lookup(var.default_cache_behavior, "forward_cookies", "none")
        }
      }
    }

    min_ttl     = lookup(var.default_cache_behavior, "cache_policy_id", null) == null ? lookup(var.default_cache_behavior, "min_ttl", 0) : null
    default_ttl = lookup(var.default_cache_behavior, "cache_policy_id", null) == null ? lookup(var.default_cache_behavior, "default_ttl", 86400) : null
    max_ttl     = lookup(var.default_cache_behavior, "cache_policy_id", null) == null ? lookup(var.default_cache_behavior, "max_ttl", 31536000) : null

    dynamic "function_association" {
      for_each = lookup(var.default_cache_behavior, "function_associations", [])
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = lookup(var.default_cache_behavior, "lambda_associations", [])
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lookup(lambda_function_association.value, "include_body", false)
      }
    }
  }

  # ---------- Comportamentos Ordenados ----------
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", "redirect-to-https")
      allowed_methods        = lookup(ordered_cache_behavior.value, "allowed_methods", ["GET", "HEAD"])
      cached_methods         = lookup(ordered_cache_behavior.value, "cached_methods", ["GET", "HEAD"])
      compress               = lookup(ordered_cache_behavior.value, "compress", true)

      cache_policy_id            = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
      origin_request_policy_id   = lookup(ordered_cache_behavior.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(ordered_cache_behavior.value, "response_headers_policy_id", null)

      dynamic "forwarded_values" {
        for_each = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? [1] : []
        content {
          query_string = lookup(ordered_cache_behavior.value, "forward_query_string", false)
          headers      = lookup(ordered_cache_behavior.value, "forward_headers", [])
          cookies {
            forward = lookup(ordered_cache_behavior.value, "forward_cookies", "none")
          }
        }
      }

      min_ttl     = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "min_ttl", 0) : null
      default_ttl = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "default_ttl", 86400) : null
      max_ttl     = lookup(ordered_cache_behavior.value, "cache_policy_id", null) == null ? lookup(ordered_cache_behavior.value, "max_ttl", 31536000) : null

      dynamic "function_association" {
        for_each = lookup(ordered_cache_behavior.value, "function_associations", [])
        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(ordered_cache_behavior.value, "lambda_associations", [])
        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lookup(lambda_function_association.value, "include_body", false)
        }
      }
    }
  }

  # ---------- Páginas de Erro Customizadas ----------
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", 10)
    }
  }

  # ---------- Restrições Geográficas ----------
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # ---------- Certificado SSL ----------
  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != null ? var.minimum_protocol_version : null
    cloudfront_default_certificate = var.acm_certificate_arn == null ? true : false
  }

  # ---------- Logs de Acesso ----------
  dynamic "logging_config" {
    for_each = var.logging_bucket != null ? [1] : []
    content {
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
      include_cookies = var.logging_include_cookies
    }
  }

  tags = merge(var.tags, {
    Name = var.distribution_name
  })
}

# ---------- Política de Bucket S3 para OAC ----------
# Usamos `create_bucket_policy` como chave de filtro — deve ser um valor
# estático (true/false) definido pelo chamador, nunca um atributo de recurso.
# Isso evita o erro "for_each keys derived from resource attributes".
resource "aws_s3_bucket_policy" "oac" {
  for_each = {
    for o in var.s3_origins : o.origin_id => o
    if lookup(o, "create_bucket_policy", true)
  }

  bucket = each.value.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${each.value.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}