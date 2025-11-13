variable "aws_region" { default = "us-east-1" }
variable "app_name"   { default = "ecom-sample" }
variable "env"        { default = "prod" }
variable "key_name"   { description = "SSH key name (not used by Fargate)" }
variable "cidr_allow" { default = "0.0.0.0/0" }
