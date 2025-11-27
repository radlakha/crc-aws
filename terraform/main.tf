terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "terraform-user"
  region  = var.aws_region
}

resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "resume_policy" {
  bucket = aws_s3_bucket.resume_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.resume_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.resume_dist.arn
          }
        }
      },
      {
        Sid       = "AllowSSOPutBucketPolicy"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::435869085347:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_CRCAdministratorAccess_613237c78a087f91"
        }
        Action = "s3:PutBucketPolicy"
        Resource = aws_s3_bucket.resume_bucket.arn
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "resume_dist" {
  origin {
    domain_name = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.resume_bucket.id

    origin_access_control_id = aws_cloudfront_origin_access_control.resume_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.resume_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "Production"
  }
}

resource "aws_cloudfront_origin_access_control" "resume_oac" {
  name                              = "resume-oac"
  description                       = "OAC for resume site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.resume_dist.domain_name
}

output "bucket_name" {
  value = aws_s3_bucket.resume_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.resume_bucket.arn
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.resume_dist.id
}