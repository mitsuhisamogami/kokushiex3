provider "aws" {
  region = var.aws_region
}

# 本番運用では S3 + DynamoDB backend へ変更すること
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "kokushiex3/prod/terraform.tfstate"
#     region         = "ap-northeast-1"
#     dynamodb_table = "your-terraform-lock-table"
#     encrypt        = true
#   }
# }

