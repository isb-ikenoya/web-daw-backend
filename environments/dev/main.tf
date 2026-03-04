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
  source  = "../../modules/route53"
  domain  = "various-ikenoya.isb-bs.com"
  owner   = local.owner
  env     = local.env
  project = local.project
}
