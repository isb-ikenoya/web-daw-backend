/*locals {
  layer_zip_path = abspath("${path.module}/layer.zip")
}*/

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layer_content"
  output_path = "${path.module}/layer.zip"
}

# レイヤーアップロード用S3
resource "aws_s3_bucket" "layer_upload" {
  # バケット名が指定されている場合のみ作成(1：作成、0：作成しない)
  count  = var.layer_upload_s3 != null ? 1 : 0
  bucket = var.layer_upload_s3.bucket_name
  tags = {
    "created_by" = var.owner
  }
}

resource "aws_s3_object" "layer_upload" {
  count  = var.layer_upload_s3 != null ? 1 : 0
  bucket = aws_s3_bucket.layer_upload.bucket
  key    = var.layer_upload_s3.key

  # アーカイブしたzipファイルを指定
  source = data.archive_file.layer_zip.output_path

  # ファイル変更時に再アップロードを促す
  source_hash = data.archive_file.layer_zip.output_base64sha256

  tags = {
    "created_by" = var.owner
  }
}

resource "aws_lambda_layer_version" "demo_layer" {
  layer_name          = "layer-demo-ikenoya"
  compatible_runtimes = ["nodejs22.x"]

  # --- S3経由の場合 ---
  s3_bucket = try(var.layer_upload_s3.bucket_name, null)
  s3_key    = try(var.layer_upload_s3.key, null)
  # S3オブジェクトが更新されたらレイヤーも更新されるように紐付け
  s3_object_version = var.layer_upload_s3 != null ? aws_s3_object.layer_upload[0].version_id : null

  # --- zipアップロードの場合 ---
  # 生成されたファイルを直接指定
  filename         = var.layer_upload_s3 == null ? data.archive_file.layer_zip.output_path : null
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
}

# lambdaソース格納用のS3bucketを作成する
resource "aws_s3_bucket" "lambda" {
  bucket = var.bucket_name

  tags = {
    "created_by" = var.owner
  }
}

# 初回デプロイ用のダミーオブジェクト
resource "aws_s3_object" "dummy" {
  bucket = aws_s3_bucket.lambda.id
  key    = "initial/lambda_fix_v4.zip"
  # リポジトリにあるzipファイルを直接指定
  source = "${path.module}/dummy.zip"
  # 以前の失敗したキャッシュを上書きするために etag を設定
  etag = filemd5("${path.module}/dummy.zip")

  tags = {
    "created_by" = var.owner
  }

  lifecycle {
    # 一度作ったら、中身が手動やCIで変わっても無視する（ソースコードの変更を検知したくない）
    ignore_changes = [source, etag]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-${var.env}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    "created_by" = var.owner
  }
}

# lambda関数
resource "aws_lambda_function" "api" {
  function_name = "${var.project}-${var.env}-api"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambdaHandler.handler" # serverless-express のエントリーポイント
  runtime       = "nodejs22.x"
  timeout       = 30
  memory_size   = 128

  # S3からコードを読み込む設定
  s3_bucket = aws_s3_bucket.lambda.id
  s3_key    = aws_s3_object.dummy.key

  layers = [aws_lambda_layer_version.demo_layer.arn]

  lifecycle {
    # 重要：GitHub Actions 側で書き換えられる項目を無視する設定
    ignore_changes = [
      s3_key,
      source_code_hash,
    ]
  }

  tags = {
    "created_by" = var.owner
  }
}

# 基本的なログ出力権限を付与
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# API Gatewayの設定
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project}-${var.env}-lambda-apigateway"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
  tags = {
    created_by = var.owner
  }
}

# Lambda関数とAPI Gatewayの統合
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST" # lambdaの場合は必ずPOST
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}" # すべてのリクエストを受け付ける
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "main-stage"
  auto_deploy = true # 変更を即時反映
}

# Lambdaの権限設定（Api Gatewayから叩けるようにする）
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name # 対象のLambda
  principal     = "apigateway.amazonaws.com"

  # どのAPI Gatewayからの呼び出しを許可するか（セキュリティ上、絞るのがベスト）
  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
