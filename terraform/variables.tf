variable "bucket_name" {
  description = "Name of S3 bucket"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}