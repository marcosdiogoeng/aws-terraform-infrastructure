# ==============================================================================
# Module: terraform-aws-alb
# ALB compartilhado com listener rules para múltiplos serviços ECS
# ==============================================================================

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  idle_timeout       = var.idle_timeout

  enable_deletion_protection       = var.deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  drop_invalid_header_fields       = var.drop_invalid_header_fields

  dynamic "access_logs" {
    for_each = try(var.access_logs.bucket, null) != null ? [var.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = try(access_logs.value.prefix, "")
      enabled = try(access_logs.value.enabled, true)
    }
  }

  tags = var.tags
}

# ==============================================================================
# Target Groups
# Um target group por serviço declarado em var.target_groups
# ==============================================================================
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = try(each.value.name, "${var.name}-${each.key}")
  port        = each.value.port
  protocol    = try(each.value.protocol, "HTTP")
  vpc_id      = var.vpc_id
  target_type = try(each.value.target_type, "ip")

  dynamic "health_check" {
    for_each = [try(each.value.health_check, {})]
    content {
      enabled             = try(health_check.value.enabled, true)
      path                = try(health_check.value.path, "/")
      matcher             = try(health_check.value.matcher, "200-299")
      healthy_threshold   = try(health_check.value.healthy_threshold, 3)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, 3)
      interval            = try(health_check.value.interval, 30)
      timeout             = try(health_check.value.timeout, 5)
      port                = try(health_check.value.port, "traffic-port")
      protocol            = try(health_check.value.protocol, try(each.value.protocol, "HTTP"))
    }
  }

  dynamic "stickiness" {
    for_each = try(each.value.stickiness.enabled, false) ? [each.value.stickiness] : []
    content {
      type            = try(stickiness.value.type, "lb_cookie")
      cookie_duration = try(stickiness.value.cookie_duration, 86400)
      enabled         = true
    }
  }

  deregistration_delay = try(each.value.deregistration_delay, 30)

  tags = merge(var.tags, try(each.value.tags, {}))

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Listener HTTP (porta 80)
# ==============================================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # Redireciona para HTTPS se houver certificado + http_redirect = true
  # Caso contrário, encaminha para o default target group
  dynamic "default_action" {
    for_each = var.https_certificate_arn != null && var.http_to_https_redirect ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = (var.https_certificate_arn == null || !var.http_to_https_redirect) && var.default_target_group != null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[var.default_target_group].arn
    }
  }

  dynamic "default_action" {
    for_each = (var.https_certificate_arn == null || !var.http_to_https_redirect) && var.default_target_group == null ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "No route matched"
        status_code  = "404"
      }
    }
  }

  tags = var.tags
}

# ==============================================================================
# Listener HTTPS (porta 443)
# ==============================================================================
resource "aws_lb_listener" "https" {
  count = var.https_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.https_certificate_arn

  dynamic "default_action" {
    for_each = var.default_target_group != null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[var.default_target_group].arn
    }
  }

  dynamic "default_action" {
    for_each = var.default_target_group == null ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "No route matched"
        status_code  = "404"
      }
    }
  }

  tags = var.tags
}

# ==============================================================================
# Listener Rules – roteamento por path e/ou host
# Cada serviço adiciona suas próprias regras chamando este módulo com
# `listener_rules`, ou via o módulo service passando `alb_listener_rules`
# ==============================================================================
resource "aws_lb_listener_rule" "http" {
  for_each = {
    for k, v in var.listener_rules : k => v
    if var.https_certificate_arn == null || !var.http_to_https_redirect
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  }

  dynamic "condition" {
    for_each = try(each.value.path_patterns, null) != null ? [1] : []
    content {
      path_pattern { values = each.value.path_patterns }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.host_headers, null) != null ? [1] : []
    content {
      host_header { values = each.value.host_headers }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.http_methods, null) != null ? [1] : []
    content {
      http_request_method { values = each.value.http_methods }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "https" {
  for_each = {
    for k, v in var.listener_rules : k => v
    if var.https_certificate_arn != null
  }

  listener_arn = aws_lb_listener.https[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  }

  dynamic "condition" {
    for_each = try(each.value.path_patterns, null) != null ? [1] : []
    content {
      path_pattern { values = each.value.path_patterns }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.host_headers, null) != null ? [1] : []
    content {
      host_header { values = each.value.host_headers }
    }
  }

  dynamic "condition" {
    for_each = try(each.value.http_methods, null) != null ? [1] : []
    content {
      http_request_method { values = each.value.http_methods }
    }
  }

  tags = var.tags
}

# ==============================================================================
# Certificados adicionais (SNI) para múltiplos domínios
# ==============================================================================
resource "aws_lb_listener_certificate" "extra" {
  for_each = toset(var.extra_certificate_arns)

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}
