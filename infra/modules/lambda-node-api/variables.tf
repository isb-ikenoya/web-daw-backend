variable "env" {
  description = "環境名"
  type        = string
}

variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "bucket_name" {
  description = "バケット名"
  type        = string
}

variable "owner" {
  description = "作成者名"
  type        = string
}

variable "layer_upload_s3" {
  description = "LambdaレイヤーにS3を使用する場合に使用する（Optional）"
  type = object({
    bucket_name = string
    key         = string
  })
  default = null
}

# Node.js関連の環境変数
variable "auth0_domain" {
  type      = string
  sensitive = true
}

variable "auth0_audience" {
  type      = string
  sensitive = true
}

