# ゾーンを作成する
resource "aws_route53_zone" "public_zone" {
  name          = var.domain
  force_destroy = false

  tags = {
    created_by = var.owner
    Name       = "${var.project}-${var.env}-domain"
    Project    = var.project
    Env        = var.env
  }
}
