resource "aws_lambda_function" "init_service" {
  function_name = "init_service"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  #architectures = [ "x86_64" ] for test in windows
  architectures    = ["arm64"]
  filename         = "${path.module}/lambdas/init_service/target/init_service.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/init_service/target/init_service.zip")
  memory_size      = 128
  timeout          = 10
}

resource "aws_lambda_function" "save_service" {
  function_name = "save_service"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  #architectures = [ "x86_64" ] for test in windows
  architectures    = ["arm64"]
  filename         = "${path.module}/lambdas/save_service/target/save_service.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/save_service/target/save_service.zip")
  memory_size      = 128
  timeout          = 10
}
