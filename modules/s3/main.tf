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

