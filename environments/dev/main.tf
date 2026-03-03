module "s3_front_end" {
  source = "../../modules/s3"
	bucket_name = "terraform-sample-bucket-ikenoya-update"
}
