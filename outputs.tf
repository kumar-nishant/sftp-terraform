output "sftp_server_endpoint" {
  description = "Hostname of the SFTP server for the vendor"
  value       = module.sftp_server.sftp_server_endpoint
}

output "sftp_user_name" {
  description = "Username for the vendor's SFTP access"
  value       = module.sftp_server.sftp_user_name
}

output "suggested_password" {
  description = "A suggested password for the SFTP user. IMPORTANT: This password must be manually set for the user via the AWS Console or CLI after the user is created."
  value       = module.sftp_server.suggested_password
  sensitive   = true # Mark as sensitive to prevent showing in logs by default
}

output "manual_password_setup_reminder" {
  description = "Reminder to manually set the password for the user"
  value       = module.sftp_server.manual_password_setup_reminder
}

output "sftp_instructions_for_vendor" {
  description = "Information to share with the vendor (excluding the password which should be shared securely)"
  value = <<EOT
SFTP Server Hostname: ${module.sftp_server.sftp_server_endpoint}
Username: ${module.sftp_server.sftp_user_name}
Authentication: Password (will be provided separately and securely)

Please use an SFTP client like FileZilla or WinSCP to connect.
EOT
}

output "sftp_bucket_name" {
  description = "Name of the S3 bucket used for SFTP storage"
  value       = module.sftp_server.sftp_bucket_name
}
