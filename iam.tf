// Lambdas
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

// Step function
resource "aws_iam_role" "step_functions_role" {
    name = "step_functions_role"
    
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "states.amazonaws.com"
            }
        }
        ]
    })
}

// Relation beetween lambda and step function //
// Data
data "aws_iam_policy_document" "lambda_access_policy" {
    statement {
        actions = [
            "lambda:*"
        ]
        resources = ["*"]
    }
}

// Policy
resource "aws_iam_policy" "step_functions_policy_lambda" {
    name   = "step_functions_policy_lambda"
    policy = data.aws_iam_policy_document.lambda_access_policy.json
}

// Role
resource "aws_iam_role_policy_attachment" "step_functions_to_lambda" {
    role       = aws_iam_role.step_functions_role.name
    policy_arn = aws_iam_policy.step_functions_policy_lambda.arn
}


// Relation beetween lambda and dynamodb //
// Data
data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:QueryInput",
      "dynamodb:Query",
      "dynamodb:PutItem",
    ]
    resources = [
        aws_dynamodb_table.tf_notes_table.arn
    ]
  }
}

// Policy
resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb_lambda_policy"
  description = "This policy will be used by the lambda to write get data from DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_to_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
}

//////////////// API GATEWAY /////////////////////

data "aws_iam_policy_document" "assume_role_policy_apigw" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_start_sfn" {
  statement {
    sid    = "ApiGwPolicy"
    effect = "Allow"
    actions = [
      "states:StartSyncExecution",
      "states:StartExecution"
    ]
    resources = [
      "*"
    ]
  }

}

resource "aws_iam_role" "iam_for_apigw_start_sfn" {
  name               = "my-apigw-exec-sfn"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_apigw.json
}

resource "aws_iam_role_policy" "policy_start_sfn" {
  policy = data.aws_iam_policy_document.policy_start_sfn.json
  role   = aws_iam_role.iam_for_apigw_start_sfn.id
}

///////////////////////////////
// Relation beetween lambda and secretmanager //
// Data
data "aws_iam_policy_document" "lambda_policy_secret" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.usercreds.arn
    ]
  }
}

// Policy
resource "aws_iam_policy" "secret_lambda_policy" {
  name        = "secret_lambda_policy"
  description = "This policy will be used by the lambda to get data from secret"
  policy      = data.aws_iam_policy_document.lambda_policy_secret.json
}

resource "aws_iam_role_policy_attachment" "lambda_to_secret" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.secret_lambda_policy.arn
}
