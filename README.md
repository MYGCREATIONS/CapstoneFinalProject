# TechnoUpdate – WordPress on AWS with Terraform

TechnoUpdate is a production-style WordPress deployment on AWS built entirely using Terraform. It provisions a secure, modular, and scalable cloud architecture including VPC, EC2, RDS, IAM, and security groups — following AWS best practices and Infrastructure as Code (IaC) principles. It is designed as a technical portfolio project to demonstrate real-world cloud architecture patterns.

---

## 1. Architecture Overview

The infrastructure includes:

1. **Custom VPC** — `10.0.0.0/16`
2. **One public subnet** — Web tier (EC2)
3. **Two private subnets** — Database tier across 2 AZs
4. **Internet Gateway and route tables** — Public/private traffic separation
5. **EC2** — Amazon Linux 2 running WordPress
6. **Private MySQL RDS** — Multi-AZ ready, never publicly accessible
7. **Scoped security groups** — Least-privilege ingress/egress
8. **IAM role** — EC2 instance profile with Systems Manager access

The database is fully isolated in private subnets and is never publicly accessible.

---

## 2. Project Structure

```
.
├── modules/
│   ├── network/
│   ├── security/
│   ├── compute/
│   └── rds/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── scripts/
    └── userdata.sh
```

The infrastructure is modularized for reusability and clarity.

---

## 3. Network Design

1. **VPC CIDR** — `10.0.0.0/16` (65,536 IP addresses)
2. **Public subnet** — Hosts the EC2 web server; route to Internet Gateway
3. **Private subnets** — Host the RDS database; no direct internet route
4. **Route tables** — Separate public and private traffic
5. **Internet Gateway** — Attached only to the public tier

This design follows a standard 2-tier architecture pattern.

---

## 4. Security Highlights

### 4.1 No Public Database

- `publicly_accessible = false`
- RDS deployed only in private subnets

### 4.2 Scoped Security Groups

**Web Security Group**

- HTTP (80) open to `0.0.0.0/0`
- SSH disabled by default; optional SSH via `ssh_allowed_cidrs` (CIDR-restricted)

**Database Security Group**

- MySQL (3306) allowed only from the Web Security Group
- No internet exposure

### 4.3 IAM Best Practice

- EC2 uses **AmazonSSMManagedInstanceCore**
- Enables secure access through AWS Systems Manager
- No need to expose SSH publicly

### 4.4 Sensitive Variables

- Passwords marked `sensitive = true`
- No hardcoded secrets
- Input validation for CIDRs, emails, and instance types

---

## 5. Compute Layer

1. **Amazon Linux 2** EC2 instance in the public subnet
2. **Bootstrapped** using `user_data`; automatically installs and configures:
   - Apache / PHP
   - WordPress
   - Database connection to RDS

---

## 6. Database Layer

1. **MySQL RDS** instance in a DB subnet group
2. **Two Availability Zones** — Subnet group spans 2 AZs for Multi-AZ readiness
3. **Optional Multi-AZ** — Toggle via RDS module variable
4. **Not publicly accessible** — Ingress only from the web security group

---

## 7. Prerequisites

1. **Terraform** — `>= 1.4.0`
2. **AWS CLI** — Configured with valid credentials
3. **AWS account** — With permissions to create VPC, EC2, RDS, IAM resources
4. **EC2 key pair** — Existing key pair in the target region (if SSH access is enabled)

---

## 8. Deployment

### Step 1 — Clone the repository

```bash
git clone <repository-url>
cd CapstoneFinalProject
```

### Step 2 — Configure variables

Edit `variables.tf` or create a `terraform.tfvars` file.

**Required (no defaults for production):**

- `db_password`
- `wp_admin_password`
- `wp_admin_user`

**Optional:**

- `aws_region`, `vpc_cidr`, subnet CIDRs
- `ssh_allowed_cidrs` — List of CIDRs allowed for SSH (e.g. `["203.0.113.0/24"]`). Leave empty to disable SSH.

Use strong passwords (minimum 12 characters).

### Step 3 — Initialize Terraform

```bash
terraform init
```

### Step 4 — Review the execution plan

```bash
terraform plan
```

### Step 5 — Apply the configuration

```bash
terraform apply
```

Confirm when prompted.

---

## 9. Outputs

After successful deployment, Terraform outputs:

1. **WordPress Public IP** — EC2 instance public IP
2. **WordPress URL** — HTTP URL to access the site
3. **RDS endpoint** — Private reference only (not publicly reachable)

---

## 10. Destroy Infrastructure

To remove all resources:

```bash
terraform destroy
```

This deletes the EC2 instance, RDS instance, VPC, IAM roles, and all associated resources.

---

## 11. Future Improvements

1. Add Application Load Balancer
2. Enable HTTPS using ACM + Route 53
3. Add Auto Scaling Group for the web tier
4. Store secrets in AWS Secrets Manager
5. Add CloudWatch monitoring and alarms
6. Convert EC2 to Launch Template for consistency and versioning
