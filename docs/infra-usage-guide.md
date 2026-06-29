# Infrastructure Diagram and Usage Guide

This document explains how to use the infrastructure diagram in this repository and how to deploy the monitoring stack correctly.

## 1. Architecture Summary

The solution deploys a secure monitoring platform on AWS with:

- An internet-facing Application Load Balancer for Grafana access
- Grafana instances in private subnets behind the ALB
- Shared storage on Amazon EFS for Grafana dashboards and plugins
- Prometheus primary and replica nodes for metrics collection
- A bastion host for secure SSH access
- Terraform remote state on Amazon S3 with DynamoDB locking
- Ansible to configure the monitoring agents and services

## 2. Diagram

Two versions of the architecture are available:

- [docs/architecture-diagram.svg](architecture-diagram.svg) — full visual diagram for viewing in VS Code or a browser.
- [docs/architecture-diagram.mmd](architecture-diagram.mmd) — Mermaid version that can be rendered in GitHub, VS Code, or Mermaid Live Editor.
- [docs/cicd-flowchart.mmd](cicd-flowchart.mmd) — dedicated CI/CD execution flowchart detailing the upstream/downstream pipelines and parameters.
- [docs/infrastructure-and-roles-guide.md](infrastructure-and-roles-guide.md) — technical reference guide detailing all AWS resource architectures and Ansible configuration roles.


### How to read the diagram
- Internet users connect to the ALB first.
- The ALB forwards traffic to the Grafana instances in private subnets.
- Grafana stores data on Amazon EFS.
- Prometheus and Node Exporter monitor the infrastructure and applications.
- The bastion host is the only admin jump host for SSH access.
- Terraform state is managed remotely in S3 with DynamoDB locking.

## 3. Prerequisites

Before deploying the stack, ensure the following are ready:

### AWS prerequisites
- AWS CLI configured with valid credentials
- IAM permissions for:
  - VPC, subnet, route table, NAT gateway, internet gateway
  - EC2, EBS, IAM role, security groups
  - ALB and target groups
  - EFS
  - S3 and DynamoDB
- A valid SSH key pair already created in AWS

### Local prerequisites
- Terraform installed (`terraform`)
- Ansible installed (`ansible-playbook`)
- Python 3 and `pip`
- Git
- A Unix-like terminal (WSL, Linux, or macOS recommended)

### Repository prerequisites
- The project cloned locally
- Correct variables updated in the Terraform config files

## 4. Recommended Folder Layout

- [README.md](../README.md) — project overview
- [terraform-ansible/terraform-monitoring-stack/terraform](../terraform-ansible/terraform-monitoring-stack/terraform) — Terraform deployment files
- [terraform-ansible/ansible-monitoring-stack](../terraform-ansible/ansible-monitoring-stack) — Ansible playbooks and roles
- [docs](.) — architecture visualization and documentation (including the diagrams and technical reference guides)

## 5. Deployment Steps

### Step 1: Bootstrap Terraform backend

If the remote backend is not already created:

1. Go to the bootstrap directory.
2. Run `terraform init`.
3. Run `terraform plan`.
4. Run `terraform apply`.

### Step 2: Deploy the infrastructure

From the Terraform root directory:

1. Run `terraform init`
2. Run `terraform plan`
3. Run `terraform apply`

This provisions the VPC, subnets, security groups, ALB, bastion host, EFS, and monitoring instances.

### Step 3: Capture the important outputs

After deployment, verify the following values from Terraform outputs:
- ALB DNS name
- Bastion public IP
- Monitoring private DNS / private IPs
- EFS DNS name
- Inventory file path

These outputs are used by the Ansible playbook and by the diagram’s runtime flow.

### Step 4: Verify generated inventory

Terraform should generate the inventory file automatically for Ansible. Confirm that the inventory contains:
- one bastion entry
- one or more monitoring nodes
- correct SSH user and proxy settings

### Step 5: Run Ansible

From the Ansible project folder:

1. Run `ansible-inventory -i inventory.ini --list`
2. Run `ansible-playbook --syntax-check site.yml`
3. Run `ansible-playbook site.yml`

### Step 6: Access the services

- Grafana URL: use the ALB DNS name from Terraform outputs
- Prometheus URL: use the monitoring host endpoint if you are connected through the bastion or a VPN
- Bastion SSH: use the bastion public IP and your private key

## 6. Security Notes

- Do not expose monitoring services directly to the internet unless required.
- Use the bastion host for admin access.
- Restrict `allowed_ssh_cidr` to trusted IP ranges.
- Ensure the SSH key pair is stored securely.

## 7. Troubleshooting

### Terraform issues
- If `terraform init` fails, verify the backend bucket and region.
- If `terraform apply` fails, check IAM permissions and variable values.

### Ansible issues
- If inventory is empty, confirm the Terraform-generated inventory file exists.
- If SSH fails, verify the private key, user name, and bastion proxy configuration.
- If playbooks fail, rerun with verbose output for targeted debugging.

## 8. Suggested Validation Commands

```bash
terraform fmt -check
terraform validate
terraform plan
ansible-playbook --syntax-check site.yml
ansible-inventory -i inventory.ini --list
```

## 9. Recommended Post-Deployment Checks

- Confirm the ALB target group is healthy.
- Confirm Grafana responds on the ALB DNS name.
- Confirm Prometheus and Node Exporter services are active on monitoring hosts.
- Confirm EFS is mounted correctly for Grafana persistence.
- Confirm logs for Ansible and Terraform runs are reviewed if any step fails.

## 10. One-Click CI/CD Deployment with Jenkins Shared Library

We use the Jenkins Shared Library concept to separate pipeline structure from operational scripts, making deployments modular and reusable.

### Jenkins Shared Library Structure
The shared steps are stored in the `jenkins-shared-library/` directory:
- `vars/runTerraform.groovy`: Custom step encapsulating Terraform lifecycle events.
- `vars/runAnsible.groovy`: Custom step encapsulating Ansible environment setup, syntax check, and playbook run.

### Setup Instructions

#### Step 1: Register Global Shared Library in Jenkins
1. Go to **Manage Jenkins** -> **Configure System** -> **Global Pipeline Libraries**.
2. Add a new library:
   - **Name**: `my-shared-library`
   - **Default Version**: `main` (or configure to point to your repository's branch)
   - **Retrieval Method**: Modern SCM (Git pointing to the repo where `jenkins-shared-library` is stored).

#### Step 2: Configure Jenkins Credentials & Mail Server
1. Create the following credentials in the Jenkins credentials store:
   - `aws-credentials-id` (Secret text or AWS credentials): The AWS Access Key ID.
   - `aws-secret-credentials-id` (Secret text): The AWS Secret Access Key.
   - `aws-ssh-key-id` (Secret file): The SSH private key (`assignment-6.pem`) for connecting to the EC2 instances.
2. Configure your SMTP mail server in Jenkins under **Manage Jenkins** -> **Configure System** -> **E-mail Notification** to allow the pipeline `mail` steps to successfully send status emails.

#### Step 3: Create Jenkins Pipeline Jobs
1. **Upstream Infrastructure Job**:
   - Create a new Pipeline job.
   - Point the pipeline script to SCM -> `jenkins/Jenkinsfile.infra`.
2. **Downstream Configuration Job**:
   - Create a new Pipeline job and name it precisely `Downstream-Ansible-Config`.
   - Point the pipeline script to SCM -> `jenkins/Jenkinsfile.ansible`.

#### Step 4: Run the Pipelines
1. Trigger the **Upstream Infrastructure Job**.
2. Select the parameters:
   - `ACTION`: Choose `apply` to deploy or `destroy` to tear down.
   - `ENVIRONMENT`: Set target environment (e.g., `dev`).
   - `NOTIFICATION_EMAIL`: Specify your email address to receive build status notifications (leave empty to disable).
3. If `apply` is run, upon success, it will automatically query Terraform outputs (`bastion_public_ip` and `efs_id`), trigger `Downstream-Ansible-Config` automatically passing along the `NOTIFICATION_EMAIL` value, and complete the full configuration of Prometheus, Grafana, and EFS.


## 11. Final Notes

This architecture is designed to be:
- scalable
- secure by default
- repeatable through infrastructure as code
- easy to troubleshoot using generated inventory and logs

