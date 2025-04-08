# --- S3 Bucket ---
resource "aws_s3_bucket" "sftp_bucket" {
  bucket = var.s3_bucket_name_unique

  # Enable versioning and server-side encryption for better data protection
  versioning {
    enabled = true
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Dedicated resource for S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sftp_bucket_sse" {
  bucket = aws_s3_bucket.sftp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "sftp_bucket_public_access" {
  bucket = aws_s3_bucket.sftp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# --- IAM Role for Transfer Family Service ---
data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "transfer_service_role" {
  name               = "tf-${var.vendor_name}-sftp-service-role"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
  description        = "IAM role for the ${var.vendor_name} SFTP Transfer Family service"
}

# Basic logging policy
data "aws_iam_policy_document" "transfer_logging_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/transfer/*"] # Restrict to transfer logs
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "transfer_logging_policy" {
  name        = "tf-${var.vendor_name}-sftp-logging-policy"
  description = "Policy for Transfer Family logging for ${var.vendor_name}"
  policy      = data.aws_iam_policy_document.transfer_logging_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "transfer_logging_attach" {
  role       = aws_iam_role.transfer_service_role.name
  policy_arn = aws_iam_policy.transfer_logging_policy.arn
}

# --- IAM Role for SFTP User ---
data "aws_iam_policy_document" "sftp_user_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "sftp_user_role" {
  name               = "tf-${var.vendor_name}-sftp-user-role-${var.sftp_user_name}"
  assume_role_policy = data.aws_iam_policy_document.sftp_user_assume_role.json
  description        = "IAM role granting S3 access for SFTP user ${var.sftp_user_name}"
}

# Policy granting access to the user's home directory in S3
data "aws_iam_policy_document" "sftp_user_s3_access" {
  # Allow listing the bucket root (needed for some clients and directory navigation)
  statement {
    sid    = "AllowListBucket"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.sftp_bucket.arn
    ]
    # Condition required for ListBucket when restricting to prefix
    condition {
       test     = "StringLike"
       variable = "s3:prefix"
       values   = ["${var.sftp_user_name}/*", "${var.sftp_user_name}"]
    }
    effect = "Allow"
  }

  # Allow GetObject, PutObject, DeleteObject within their home directory prefix
  statement {
    sid = "AllowUserHomeDirectoryAccess"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion" # Useful if versioning is enabled
    ]
    resources = [
      "${aws_s3_bucket.sftp_bucket.arn}/${var.sftp_user_name}/*", # Access to objects within home dir
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "sftp_user_s3_policy" {
  name        = "tf-${var.vendor_name}-sftp-user-s3-policy-${var.sftp_user_name}"
  description = "S3 access policy for SFTP user ${var.sftp_user_name}"
  policy      = data.aws_iam_policy_document.sftp_user_s3_access.json
}

resource "aws_iam_role_policy_attachment" "sftp_user_s3_attach" {
  role       = aws_iam_role.sftp_user_role.name
  policy_arn = aws_iam_policy.sftp_user_s3_policy.arn
}

# --- Transfer Family Server ---
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED" # Use Transfer Family managed users/keys
  logging_role           = aws_iam_role.transfer_service_role.arn
  protocols              = ["SFTP"]

  tags = merge(var.tags, {
    Name = "sftp-server-${var.vendor_name}"
  })
}

# Create the user's home directory prefix in S3
resource "aws_s3_object" "user_home_folder" {
  bucket = aws_s3_bucket.sftp_bucket.id
  key    = "${var.sftp_user_name}/" # Creates an empty object representing the directory
  content_type = "application/x-directory" # Hint to S3 that this is a folder-like object
  tags = merge(var.tags, {
    Name = "home-folder-${var.sftp_user_name}"
  })
}

# --- Transfer Family User ---
resource "aws_transfer_user" "vendor_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = var.sftp_user_name
  role           = aws_iam_role.sftp_user_role.arn
  home_directory = "/${aws_s3_bucket.sftp_bucket.id}/${var.sftp_user_name}"

  # Public key must be added manually via Console/CLI for SERVICE_MANAGED users

  tags = merge(var.tags, {
    Name   = var.sftp_user_name
    Vendor = var.vendor_name
  })

  depends_on = [aws_s3_object.user_home_folder]
}

# --- Suggested Password Generation ---
resource "random_password" "suggested_password" {
  length           = 16
  special          = true
  override_special = "_%@" # Characters allowed by AWS Transfer passwords
}

# --- Optional: CloudWatch Log Group ---
# Transfer Family will log automatically if the role permits, but you can define the group explicitly
resource "aws_cloudwatch_log_group" "transfer_logs" {
  name              = "/aws/transfer/${aws_transfer_server.sftp_server.id}"
  retention_in_days = 30 # Adjust retention as needed

  tags = merge(var.tags, {
    Name = "transfer-logs-${var.vendor_name}"
  })
}
