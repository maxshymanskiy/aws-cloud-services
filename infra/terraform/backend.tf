terraform {
  backend "s3" {
    # Leave these empty and they will be filled by backend.config
    bucket         = ""
    key            = ""
    region         = ""
    dynamodb_table = ""
    encrypt        = true
  }
}
