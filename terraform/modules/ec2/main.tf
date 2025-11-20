resource "tls_private_key" "this" {
  count     = var.generate_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  count      = var.generate_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = tls_private_key.this[0].public_key_openssh
}

resource "aws_iam_role" "this" {
  count = var.attach_ssm_role ? 1 : 0

  name = "${var.project_name}-${var.instance_name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}-ssm-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.attach_ssm_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  count = var.attach_ssm_role ? 1 : 0

  name = "${var.project_name}-${var.instance_name}-ssm-instance-profile"
  role = aws_iam_role.this[0].name

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}-ssm-instance-profile"
      Environment = var.environment
    }
  )
}

resource "aws_s3_object" "this" {
  count        = var.generate_key_pair && var.store_key_in_s3 ? 1 : 0
  bucket       = var.s3_bucket_name
  key          = var.s3_key_name
  content      = tls_private_key.this[0].private_key_pem
  content_type = "application/x-pem-file"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}-private-key"
      Environment = var.environment
    }
  )
}

resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = "${var.project_name}-${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} in project ${var.project_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_rules.ingress
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules.egress
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = egress.value.cidr_blocks
      security_groups = lookup(egress.value, "security_groups", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}-sg"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ingress, egress]
  }
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
  key_name                    = var.generate_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  iam_instance_profile        = var.attach_ssm_role ? aws_iam_instance_profile.this[0].name : null
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  monitoring                  = var.enable_detailed_monitoring
  disable_api_termination     = var.disable_api_termination

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = lookup(ebs_block_device.value, "iops", null)
      encrypted             = lookup(ebs_block_device.value, "encrypted", true)
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device != null ? [var.root_block_device] : []
    content {
      volume_type           = root_block_device.value.volume_type
      volume_size           = root_block_device.value.volume_size
      iops                  = lookup(root_block_device.value, "iops", null)
      encrypted             = lookup(root_block_device.value, "encrypted", true)
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", true)
      throughput            = lookup(root_block_device.value, "throughput", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}"
      Environment = var.environment
    }
  )
}

resource "aws_eip" "this" {
  count      = var.associate_eip ? 1 : 0
  instance   = aws_instance.this.id
  domain     = "vpc"
  depends_on = [aws_instance.this]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.instance_name}-eip"
      Environment = var.environment
    }
  )
}