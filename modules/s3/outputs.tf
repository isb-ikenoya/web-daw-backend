output "domain_name" {
  description = "FQDN"
  value       = aws_s3_bucket.front.bucket_regional_domain_name
}

output "bucket_name" {
  description = "バケット名"
  value       = aws_s3_bucket.front.bucket
}

output "cloudfront_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
}
