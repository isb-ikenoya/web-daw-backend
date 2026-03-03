module "global_variables" {
  // 共通で使用する定数
  source = "../../modules/grobal-variables/"
}

locals {
  owner = module.global_variables.owner
}

module "s3_front_end" {
  source      = "../../modules/s3"
  bucket_name = "terraform-sample-bucket-ikenoya-update"
  owner       = local.owner
}
