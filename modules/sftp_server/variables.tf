variable "region" {
  description = "AWS region"
  type        = string
}

variable "vendor_name" {
  description = "Unique name for the vendor"
  type        = string
}

variable "sftp_user_name" {
  description = "Username for the SFTP user"
  type        = string
}

variable "s3_bucket_name_unique" {
  description = "The globally unique name for the S3 bucket."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
