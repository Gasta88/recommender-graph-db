provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

#--------------------------- Locals declaration
locals {
  env = {
    dev = {
      #   source_bucket = "ef-staging"
      #   media_bucket  = "media-library-staging"
    }
    e2e-test = {
      #   source_bucket = "None"
      #   media_bucket  = "media-library-staging"
    }
  }
  environmentvars = contains(keys(local.env), terraform.workspace) ? terraform.workspace : "dev"
  workspace       = merge(local.env["dev"], local.env[local.environmentvars])
}
#--------------------------- S3 and S3 objects
resource "aws_s3_bucket" "data-bucket" {
  bucket = "recommender-graph-db-${terraform.workspace}"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  versioning {
    enabled = false
  }
}

# resource "null_resource" "upload-to-s3" {
#   provisioner "local-exec" {
#     command = "aws s3 cp ../data/raw/ s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/ --recursive --exclude '*.DS_Store'"
#   }
# }


#--------------------------- AWS Glue resources

resource "aws_iam_role" "glue-role" {
  name                = "recommender-graph-db-glue-role-${terraform.workspace}"
  path                = "/"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole", aws_iam_policy.s3-data-policy.arn]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3-data-policy" {
  name = "data-policy-recommender-graph-db-${terraform.workspace}"
  path = "/"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject", "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.data-bucket.bucket}/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.data-bucket.bucket}"
      },
      {
        Action = [
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.data-bucket.bucket}/data/*"
      },
      {
        Action = [
          "logs:GetLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws-glue/python-jobs/output:*"
      },
      {
        Action = [
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws-glue/python-jobs/output:*"
      }
    ]
  })
}

resource "aws_glue_catalog_database" "catalog-database" {
  name        = "recommender_graph_db_${terraform.workspace}"
  description = "Customers tables for Athena"
}

resource "aws_glue_crawler" "raw-data-crawler-customer-1" {
  database_name = aws_glue_catalog_database.catalog-database.name
  name          = "recommender-graph-db-raw-data-c1-${terraform.workspace}"
  role          = aws_iam_role.glue-role.arn
  table_prefix  = "c1_${terraform.workspace}_"

  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_1/core_user.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_1/learning_course.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_1/learning_course_rating_vote.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_1/learning_courseuser.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_1/core_setting_user.parquet" }
}

resource "aws_glue_crawler" "raw-data-crawler-customer-2" {
  database_name = aws_glue_catalog_database.catalog-database.name
  name          = "recommender-graph-db-raw-data-c2-${terraform.workspace}"
  role          = aws_iam_role.glue-role.arn
  table_prefix  = "c2_${terraform.workspace}_"

  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/core_user.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/learning_course.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/learning_course_rating_vote.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/app7020_content_history.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/app7020_content.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/app7020_content_rating.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/learning_courseuser.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_2/core_setting_user.parquet" }
}
resource "aws_glue_crawler" "raw-data-crawler-customer-3" {
  database_name = aws_glue_catalog_database.catalog-database.name
  name          = "recommender-graph-db-raw-data-c3-${terraform.workspace}"
  role          = aws_iam_role.glue-role.arn
  table_prefix  = "c3_${terraform.workspace}_"

  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/core_user.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/learning_course.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/learning_course_rating_vote.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/learning_courseuser.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/core_setting_user.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/app7020_content_history.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/app7020_content_rating.parquet" }
  s3_target { path = "s3://${aws_s3_bucket.data-bucket.bucket}/data/raw/customer_3/app7020_content.parquet" }
}

resource "null_resource" "run-crawler-customer-1" {
  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${aws_glue_crawler.raw-data-crawler-customer-1.id}"
  }
  depends_on = [
    aws_glue_catalog_database.catalog-database, aws_glue_crawler.raw-data-crawler-customer-1
  ]
}

resource "null_resource" "run-crawler-customer-2" {
  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${aws_glue_crawler.raw-data-crawler-customer-2.id}"
  }
  depends_on = [
    aws_glue_catalog_database.catalog-database, aws_glue_crawler.raw-data-crawler-customer-2
  ]
}

resource "null_resource" "run-crawler-customer-3" {
  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${aws_glue_crawler.raw-data-crawler-customer-3.id}"
  }
  depends_on = [
    aws_glue_catalog_database.catalog-database, aws_glue_crawler.raw-data-crawler-customer-3
  ]
}




