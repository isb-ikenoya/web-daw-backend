variable "owner" {
  description = "作成者名"
  type        = string
}

variable "env" {
  description = "環境名"
  type        = string
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "acm_certificate_arn" {
  description = "証明書arn"
  type        = string
}

variable "origin_domain_name" {
  description = "オリジンドメイン名"
  type        = string
}

variable "origin_id" {
  description = "一意なオリジンID"
  type        = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "s3_bucket_id" {
  type = string
}

variable "aliase_domain" {
  description = "代替ドメイン"
  type        = string
}
