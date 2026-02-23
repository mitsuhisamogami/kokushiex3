data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix      = "${var.project}-${var.environment}"
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  app_fqdn         = "${var.app_subdomain}.${var.domain_name}"
  enable_alb_https = var.alb_certificate_arn != ""
  app_url_scheme   = local.enable_alb_https ? "https" : "http"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
