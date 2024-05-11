resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my_api_notes"
  description = "My API Gateway"

}

resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "mypath"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "POST"
  authorization = "NONE"
}


// Deploy
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id

  depends_on = [
    aws_api_gateway_integration.my_integration_step_function
  ]
}

// INTEGRATION

// Integración con Step function
resource "aws_api_gateway_integration" "my_integration_step_function" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.my_resource.id

  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  #type = "MOCK"
  type = "AWS"
  uri  = "arn:aws:apigateway:us-east-1:states:action/StartExecution"


  credentials = aws_iam_role.iam_for_apigw_start_sfn.arn

  request_templates = {
    "application/json" = <<EOF
    #set($input = $input.json('$'))
    {
        "input": "$util.escapeJavaScript($input).replaceAll("\\'", "'")",
        "stateMachineArn": "${aws_sfn_state_machine.my_processor_sf.arn}"
    }
    EOF
  }
}

output "url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/mypath"
}

resource "aws_api_gateway_method_response" "express_response_200" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "express_response_200" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.express_response_200.status_code

  response_templates = {
    "application/json" = <<EOF
    #set ($parsedPayload = $util.parseJson($input.json('$.output')))
    $parsedPayload
    EOF
  }

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_method.post_method, aws_api_gateway_integration.my_integration_step_function]
}
