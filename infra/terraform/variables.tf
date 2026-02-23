variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "kokushiex"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "2 public subnet CIDRs"
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "2 private subnet CIDRs"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "domain_name" {
  type        = string
  description = "Root domain managed in Route53 (e.g. kokushiex.com)"
}

variable "app_subdomain" {
  type        = string
  description = "Application subdomain (e.g. app)"
  default     = "app"
}

variable "alb_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS listener (empty to disable HTTPS listener)"
  default     = ""
}

variable "app_image" {
  type        = string
  description = "Container image URI for web/worker (ECR URI with tag)"
}

variable "ec2_instance_type" {
  type        = string
  description = "ECS container instance type"
  default     = "t3.small"
}

variable "db_name" {
  type        = string
  description = "RDS database name"
  default     = "kokushiex"
}

variable "db_username" {
  type        = string
  description = "RDS username"
  default     = "kokushiex"
}

variable "db_password" {
  type        = string
  description = "RDS password"
  sensitive   = true
}

variable "db_engine_version" {
  type        = string
  description = "RDS PostgreSQL engine version (null to let AWS choose an available version)"
  default     = null
}

variable "secret_key_base" {
  type        = string
  description = "Rails SECRET_KEY_BASE"
  sensitive   = true
}

variable "rails_master_key" {
  type        = string
  description = "Rails master key"
  sensitive   = true
}

variable "sentry_dsn" {
  type        = string
  description = "Sentry DSN"
  sensitive   = true
  default     = ""
}

variable "sendgrid_api_key" {
  type        = string
  description = "SendGrid API key"
  sensitive   = true
  default     = ""
}

variable "sidekiq_username" {
  type        = string
  description = "Sidekiq basic auth username"
  sensitive   = true
}

variable "sidekiq_password" {
  type        = string
  description = "Sidekiq basic auth password"
  sensitive   = true
}

variable "alarm_notification_email" {
  type        = string
  description = "Email address for CloudWatch alarm notifications (empty to skip email subscription)"
  default     = ""
}
