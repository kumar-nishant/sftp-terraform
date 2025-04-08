# AWS SFTP Server via Terraform

This Terraform project automates the deployment of a secure SFTP (SSH File Transfer Protocol) server on AWS using the AWS Transfer Family service.

**Purpose:**

To provide a secure, reliable, and automated mechanism for exchanging files with external partners or systems via the SFTP protocol.

**Features:**

*   **Automated Deployment:** Infrastructure is defined as code using Terraform, enabling repeatable and version-controlled deployments.
*   **Secure Storage:** Utilizes an S3 bucket for backend storage, configured with server-side encryption and blocked public access.
*   **Fine-Grained Permissions:** Leverages IAM roles and policies to ensure the SFTP service and users have only the necessary permissions (principle of least privilege). User access is restricted to designated home directories within the S3 bucket.
*   **Managed Service:** Uses AWS Transfer Family, reducing the operational overhead of managing traditional SFTP server infrastructure.
*   **Modular Design:** The Terraform code is structured into reusable modules for better organization and maintainability.
*   **Logging:** Configured to send server access logs to CloudWatch Logs for monitoring and auditing.

**How it Works:**

This configuration provisions:

1.  An AWS Transfer Family server endpoint.
2.  An S3 bucket dedicated to storing transferred files.
3.  Necessary IAM roles and policies for the Transfer Family service and SFTP users.
4.  An SFTP user resource within Transfer Family (authentication details like SSH keys or passwords need to be managed according to the chosen identity provider setup).

This setup allows authorized users to connect via standard SFTP clients and securely upload/download files, which are stored directly in the designated S3 bucket.

**For multiple Environments:**
*   **Create Environment-Specific .tfvars Files:**
    
Create a new file for each environment, for example:
   
1. terraform.dev.tfvars (for development)
2. terraform.staging.tfvars (for staging)
3. terraform.prod.tfvars (for production)

Each file will contain the environment-specific values for variables defined in variables.tf.

* terraform apply -var-file="terraform.dev.tfvars" -state="terraform.dev.tfstate"
* terraform apply -var-file="terraform.staging.tfvars" -state="terraform.staging.tfstate"
* terraform apply -var-file="terraform.prod.tfvars" -state="terraform.prod.tfstate"
