variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Or your preferred region
}

variable "vendor_name" {
  description = "A unique name for the vendor (used for resource naming)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vendor_name))
    error_message = "Vendor name must contain only letters, numbers, and hyphens."
  }
}

variable "sftp_user_name" {
  description = "The username for the vendor to use for SFTP login"
  type        = string
  validation {
    // AWS Transfer User constraints: ^[a-zA-Z0-9_][a-zA-Z0-9_-]{2,99}$
    condition     = can(regex("^[a-zA-Z0-9_][a-zA-Z0-9_-]{2,99}$", var.sftp_user_name))
    error_message = "Username must be 3-100 chars, start with letter/number/underscore, and contain only letters, numbers, underscore, or hyphen."
  }
}

variable "s3_bucket_name_prefix" {
  description = "Prefix for the S3 bucket name. A random suffix will be added."
  type        = string
  default     = "vendor-sftp-data"
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
