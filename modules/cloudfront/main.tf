# OACの設定
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-${var.env}-s3-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront
resource "aws_cloudfront_distribution" "this" {
  # 基本設定

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "WebDaw用"
  default_root_object = "index.html"
  aliases             = [var.aliase_domain]

  tags = {
    Name       = "WebDaw-CloudFront"
    created_by = var.owner
  }

  # 価格クラス
  price_class = "PriceClass_200" # アジア・ヨーロッパ・北米をカバー

  # アクセス制限（地域設定は料金がかからない？）
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"] # 日本のみアクセス可能
    }
  }

  origin {
    domain_name              = var.origin_domain_name
    origin_id                = var.origin_id                              # オリジンの一意のID
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id # OAC
    /*s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }*/
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # 証明書
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html" # SPAのルーティング対応
  }

}

# CloudFront関連のS3バケットポリシーの更新
# S3バケットポリシー
data "aws_iam_policy_document" "front" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn] # CloudFrontのARNを指定
    }
  }
}

resource "aws_s3_bucket_policy" "front" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.front.json
}

# CloudFrontのURLをRoute53に登録

# 対象のホストゾーンの情報を取得する（データソース）
data "aws_route53_zone" "this" {
  name         = var.aliase_domain # 対象のドメイン
  private_zone = false             # パブリックの場合
}

# Aレコードを追加する
resource "aws_route53_record" "record_a" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.aliase_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAAレコードを追加する
resource "aws_route53_record" "record_aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.aliase_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

