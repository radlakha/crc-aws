terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}

resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "resume_bucket" {
  bucket = aws_s3_bucket.resume_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
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

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.resume_oai.cloudfront_access_identity_path
    }
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

resource "aws_cloudfront_origin_access_identity" "resume_oai" {
  comment = "OAI for resume site"
}