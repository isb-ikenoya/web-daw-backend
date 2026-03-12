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
