variable "parent_domain" {
  description = "親のドメイン"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "自身のドメイン"
  type        = string
  sensitive   = true
}

/*variable "package_lock_hash" {
  description = "backend/package-lock.json のハッシュ値"
  type        = string
}*/

# Node.js関連の環境変数
variable "auth0_domain" {
  type      = string
  sensitive = true
}

variable "auth0_audience" {
  type      = string
  sensitive = true
}
