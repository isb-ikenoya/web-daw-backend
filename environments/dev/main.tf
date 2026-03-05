module "global_variables" {
  // 共通で使用する定数
  source = "../../modules/grobal-variables/"
}

locals {
  owner   = module.global_variables.owner
  project = module.global_variables.project
  env     = "dev"
}

module "s3_front_end" {
  source      = "../../modules/s3"
  bucket_name = "${local.project}-${local.env}-bucket"
  owner       = local.owner
}

module "route53" {
  source        = "../../modules/route53"
  parent_domain = var.parent_domain
  domain        = var.domain
  owner         = local.owner
  env           = local.env
  project       = local.project
}

module "acm" {
  source = "../../modules/acm"
  providers = {
    aws = aws.virginia
  }

  domain  = var.domain
  owner   = local.owner
  project = local.project
  env     = local.env
  zone_id = module.route53.zone_id

  depends_on = [module.route53]
}

module "cloud_front" {
  source              = "../../modules/cloudfront"
  owner               = local.owner
  env                 = local.env
  project             = local.project
  acm_certificate_arn = module.acm.certificate_arn
  origin_domain_name  = module.s3_front_end.domain_name
  origin_id           = "S3-${module.s3_front_end.bucket_name}"
  s3_bucket_arn       = module.s3_front_end.bucket_arn
  aliase_domain       = var.domain
}
