output "sftp_server_endpoint" {
  description = "Hostname of the SFTP server"
  value       = aws_transfer_server.sftp_server.endpoint
}

output "sftp_user_name" {
  description = "Username for the SFTP user"
  value       = aws_transfer_user.vendor_user.user_name
}

output "sftp_bucket_name" {
  description = "Name of the S3 bucket used for SFTP storage"
  value       = aws_s3_bucket.sftp_bucket.bucket
}

output "suggested_password" {
  description = "A suggested password for the SFTP user. IMPORTANT: This password must be manually set for the user via the AWS Console or CLI after the user is created."
  value       = random_password.suggested_password.result
  sensitive   = true
}

output "manual_password_setup_reminder" {
  description = "Reminder to manually set the password for the user"
  value       = "IMPORTANT: Manually set the password for user '${var.sftp_user_name}' on server '${aws_transfer_server.sftp_server.id}' via AWS Console/CLI using the 'suggested_password' output or your own secure password."
}

output "sftp_user_role_arn" {
  description = "ARN of the IAM role assigned to the SFTP user."
  value       = aws_iam_role.sftp_user_role.arn
}

output "transfer_server_id" {
  description = "ID of the AWS Transfer Family server."
  value       = aws_transfer_server.sftp_server.id
}
