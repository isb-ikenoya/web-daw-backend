locals {
  backend_dir  = "${path.module}/../../../backend"
  package_json = "${local.backend_dir}/package.json"
  package_lock = "${local.backend_dir}/package-lock.json"
  # レイヤー作成用の作業ディレクトリ
  layer_build_path = "${path.module}/build_layer"
}

resource "terraform_data" "prepare_layer" {
  triggers_replace = {
    # package.json か lockファイルが変わったら再インストール
    package_json_sha = filesha256(local.package_json)
    package_lock_sha = filesha256(local.package_lock)
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      
      # 1. Node.js のポータブルバイナリをダウンロード
      # .tar.xz ではなく .tar.gz を使用し、tar のオプションから J を外して z にする
      NODE_VERSION="v22.14.0" # 2026年3月時点のLTS最新
      echo "Downloading Node.js $NODE_VERSION (tar.gz)..."
      curl -sL https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.gz | tar -xz
      
      export PATH="$PWD/node-$NODE_VERSION-linux-x64/bin:$PATH"

      # 確認
      node -v
      npm -v

      # 2. 以降はこれまでのビルド手順（絶対パスを使用）
      rm -rf "${local.layer_build_path}"
      mkdir -p "${local.layer_build_path}/nodejs"
      
      cp "${local.backend_dir}/package.json" "${local.layer_build_path}/nodejs/"
      cp "${local.backend_dir}/package-lock.json" "${local.layer_build_path}/nodejs/"
      
      cd "${local.layer_build_path}/nodejs"
      npm install --production
      
      # 最後に「ビルド完了フラグ」としてタイムスタンプファイルを作成
      date > "${local.layer_build_path}/build_complete.txt"
    EOT
  }
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = local.layer_build_path
  output_path = "${path.module}/layer.zip"
  depends_on  = [terraform_data.prepare_layer]
}

resource "aws_lambda_layer_version" "demo_layer" {
  filename            = data.archive_file.layer_zip.output_path
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
  layer_name          = "layer-demo-ikenoya"
  compatible_runtimes = ["nodejs22.x"]
  depends_on          = [data.archive_file.layer_zip]
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
