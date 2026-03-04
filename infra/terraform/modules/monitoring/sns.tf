module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  name    = "alerts"
}

# SNS topic — single notification channel shared by all alarms in this module
resource "aws_sns_topic" "this" {
  name = module.label.id
  tags = module.label.tags
}

# Email subscription — one subscriber, one responsibility
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
