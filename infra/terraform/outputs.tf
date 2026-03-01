# Provide a link in termial, to invoke the API Gateway endpoint to test 
# the lambda functions and CORS configuration.
output "api_invoke_url" {
  description = "Base invoke URL for the API stage"
  value       = module.api_gateway.invoke_url
}
