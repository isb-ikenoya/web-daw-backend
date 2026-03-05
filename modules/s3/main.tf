# S3のbucketを作成する
resource "aws_s3_bucket" "front" {
  bucket = var.bucket_name

  tags = {
    "created_by" = var.owner
  }
}

# パブリックアクセスをブロックする設定
resource "aws_s3_bucket_public_access_block" "front" {
  bucket                  = aws_s3_bucket.front.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAIの作成
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${aws_s3_bucket.front.bucket}"
}

# S3バケットポリシー
resource "aws_s3_bucket_policy" "front" {
  bucket = aws_s3_bucket.front.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.front.arn}/*"
      }
    ]
  })
}
