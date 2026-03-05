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
  bucket = aws_s3_bucket.front.id
  policy = data.aws_iam_policy_document.front.json
}
