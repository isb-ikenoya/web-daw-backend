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
  handler       = "index.handler" # serverless-express のエントリーポイント
  runtime       = "nodejs24.x"
  timeout       = 30
  memory_size   = 128

  # S3からコードを読み込む設定
  s3_bucket = aws_s3_bucket.lambda.id
  s3_key    = aws_s3_object.dummy.key

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
