resource "aws_acm_certificate" "virginia_cert" {

  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    created_by = var.owner
    Name       = "${var.project}-${var.env}-wildcard-sslcert"
    Project    = var.project
    Env        = var.env
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_route53_zone.route53_zone
  ]
}
