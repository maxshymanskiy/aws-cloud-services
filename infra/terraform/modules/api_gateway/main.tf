module "api_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  context = var.context
  name    = "api"
}

resource "aws_api_gateway_rest_api" "this" {
  name        = module.api_label.id
  description = "API for courses management"
}

resource "aws_api_gateway_resource" "authors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "authors"
}

resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "courses"
}

resource "aws_api_gateway_resource" "course_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{id}"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.authors.id,
      aws_api_gateway_resource.courses.id,
      aws_api_gateway_resource.course_id.id,
      aws_api_gateway_method.get_authors.id,
      aws_api_gateway_method.get_courses.id,
      aws_api_gateway_method.post_courses.id,
      aws_api_gateway_method.get_course_id.id,
      aws_api_gateway_method.put_course_id.id,
      aws_api_gateway_method.delete_course_id.id,
      aws_api_gateway_method.options_authors.id,
      aws_api_gateway_method.options_courses.id,
      aws_api_gateway_method.options_course_id.id,
      aws_api_gateway_integration.get_authors,
      aws_api_gateway_integration.get_courses,
      aws_api_gateway_integration.post_courses,
      aws_api_gateway_integration.get_course_id,
      aws_api_gateway_integration.put_course_id,
      aws_api_gateway_integration.delete_course_id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_authors,
    aws_api_gateway_integration.get_courses,
    aws_api_gateway_integration.post_courses,
    aws_api_gateway_integration.get_course_id,
    aws_api_gateway_integration.put_course_id,
    aws_api_gateway_integration.delete_course_id,
    aws_api_gateway_integration.options_authors,
    aws_api_gateway_integration.options_courses,
    aws_api_gateway_integration.options_course_id,
  ]
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1"
}
