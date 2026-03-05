resource "aws_cloudfront_distribution" "this" {
  # 基本設定
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "WebDaw用"
  default_root_object = "index.html"

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
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id # オリジンの一意のID
    s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }
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
