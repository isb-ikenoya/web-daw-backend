variable "owner" {
  description = "作成者名"
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

variable "origin_access_identity" {
  type = string
}
