###############################################################
# Load Balancer and Listener Configuration for ClearML
#
# This file provisions the following AWS resources:
# - Security group for the load balancer with HTTP/HTTPS and app ports
# - Application Load Balancer (ALB) for ClearML services
# - Target groups for web, API, and file endpoints
# - HTTPS listeners and rules for routing to subdomains
# - Target group attachments for EC2 instance
# - SNI certificates for all listeners
# - HTTP to HTTPS redirect
#
# Ensures secure, scalable, and flexible access to ClearML services.
###############################################################

resource "aws_security_group" "lb_sg" {
  name        = "clearml_lb_sg"
  description = "Allow HTTPS traffic"
  vpc_id      = module.vpc.vpc_id
  
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "clearml_lb" {
  name                       = "clearml-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  preserve_host_header       = true
}

resource "aws_lb_target_group" "tg_8080" {
  name     = "WebTargetGroup"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_target_group" "tg_8008" {
  name     = "ApiTargetGroup"
  port     = 8008
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/debug.ping"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_target_group" "tg_8081" {
  name     = "FileTargetGroup"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "listener_8080" {
  load_balancer_arn = aws_lb.clearml_lb.arn
  port              = 8080
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert_acm_clearml.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8080.arn
  }
}

resource "aws_lb_listener" "listener_8008" {
  load_balancer_arn =  aws_lb.clearml_lb.arn
  port              = 8008
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert_acm_clearml.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8008.arn
  }
}

resource "aws_lb_listener" "listener_8081" {
  load_balancer_arn =  aws_lb.clearml_lb.arn
  port              = 8081
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert_acm_clearml.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8081.arn
  }
}

resource "aws_lb_listener" "listener_443" {
  load_balancer_arn = aws_lb.clearml_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert_acm_clearml.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8080.arn
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.listener_443.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8080.arn
  }

  condition {
    host_header {
      values = ["${var.subdomains["app"]}.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.listener_443.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8008.arn
  }

  condition {
    host_header {
       values = ["${var.subdomains["api"]}.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "files" {
  listener_arn = aws_lb_listener.listener_443.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_8081.arn
  }

  condition {
    host_header {
       values = ["${var.subdomains["files"]}.${var.domain_name}"]
    }
  }
}

resource "aws_lb_target_group_attachment" "app_8080" {
  target_group_arn = aws_lb_target_group.tg_8080.arn
  target_id        = aws_instance.clearmlserver.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "api_8008" {
  target_group_arn = aws_lb_target_group.tg_8008.arn
  target_id        = aws_instance.clearmlserver.id
  port             = 8008
}

resource "aws_lb_target_group_attachment" "file_8081" {
  target_group_arn = aws_lb_target_group.tg_8081.arn
  target_id        = aws_instance.clearmlserver.id
  port             = 8081
}

resource "aws_lb_listener_certificate" "sni_clearml_lb_8081" {
  listener_arn    = aws_lb_listener.listener_8081.arn
  certificate_arn = aws_acm_certificate.cert_acm_clearml.arn
}

resource "aws_lb_listener_certificate" "sni_clearml_lb_8008" {
  listener_arn    = aws_lb_listener.listener_8008.arn
  certificate_arn = aws_acm_certificate.cert_acm_clearml.arn
}

resource "aws_lb_listener_certificate" "sni_clearml_lb_8080" {
  listener_arn    = aws_lb_listener.listener_8080.arn
  certificate_arn = aws_acm_certificate.cert_acm_clearml.arn
}

resource "aws_lb_listener_certificate" "sni_clearml_lb_443" {
  listener_arn    = aws_lb_listener.listener_443.arn
  certificate_arn = aws_acm_certificate.cert_acm_clearml.arn
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.clearml_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

