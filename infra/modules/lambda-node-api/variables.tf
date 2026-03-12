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

variable "package_lock_hash" {
  description = "backend/package-lock.json のハッシュ値"
  type        = string
}
