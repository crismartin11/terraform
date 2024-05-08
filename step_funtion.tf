# Step Functions State Machine
resource "aws_sfn_state_machine" "my_processor_sf" {
    name     = "my_processor_sf"
    role_arn = aws_iam_role.step_functions_role.arn

    definition = <<EOF
{
    "Comment": "execute lambdas",
    "StartAt": "InitService",
    "States": {
    "InitService": {
        "Type": "Task",
        "Resource": "${aws_lambda_function.init_service.arn}",
        "Next": "SaveService"
    },
    "SaveService": {
        "Type": "Task",
        "Resource": "${aws_lambda_function.save_service.arn}",
        "End": true
    }
    }
}
EOF
}