
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-upgrade-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda-upgrade-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "upgrade_lambda_runtime" {
  filename         = "lambda.zip"
  function_name    = "upgrade_lambda_runtime"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "upgrade_runtime.main"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "python3.11"
  timeout          = 300
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "daily-upgrade-schedule"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "UpgradeLambdaTarget"
  arn       = aws_lambda_function.upgrade_lambda_runtime.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upgrade_lambda_runtime.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
