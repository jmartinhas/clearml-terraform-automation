###############################################################
# Network and DNS Configuration for ClearML Deployment
#
# This file provisions networking resources including:
# - Security group for ClearML server with SSH and load balancer ingress rules
# - Security group rules for web, API, and file ports
# - Route53 DNS records for ClearML subdomains
# - ACM certificate and DNS validation for HTTPS
#
# Ensures secure and accessible networking for ClearML services.
###############################################################

resource "aws_security_group" "clearml_server_sg" {
  name        = "clearml_server_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  count = var.ssh_port22 ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere; for better security, restrict to your IP
  security_group_id = aws_security_group.clearml_server_sg.id
}

resource "aws_security_group_rule" "allow_lb_web_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.clearml_server_sg.id
  source_security_group_id = aws_security_group.lb_sg.id
  depends_on = [ aws_security_group.clearml_server_sg ]
}

resource "aws_security_group_rule" "allow_lb_api_ingress" {
  type              = "ingress"
  from_port         = 8008
  to_port           = 8008
  protocol          = "tcp"
  security_group_id = aws_security_group.clearml_server_sg.id
  source_security_group_id = aws_security_group.lb_sg.id
  depends_on = [ aws_security_group_rule.allow_lb_web_ingress ]
}

resource "aws_security_group_rule" "allow_lb_file_ingress" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "tcp"
  security_group_id = aws_security_group.clearml_server_sg.id
  source_security_group_id = aws_security_group.lb_sg.id
  depends_on = [ aws_security_group_rule.allow_lb_api_ingress ]
}

# Create a DNS record

resource "aws_route53_record" "alias_clearmlserver" {
  for_each = var.subdomains

  zone_id = data.aws_route53_zone.zone_name.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.clearml_lb.dns_name
    zone_id                = aws_lb.clearml_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert_acm_clearml" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [for k, v in var.subdomains : "${v}.${var.domain_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert_acm_clearml.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone_name.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.cert_acm_clearml.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}