<p align="right"><img src="./terraform-svgrepo-com.svg" width="64" alt="Terraform Logo" /></p>

# Assignment 05 - Enterprise Monitoring Stack using Terraform & Ansible

## Author

- Anurag Maurya
- DevOps implementation for a monitoring platform using AWS infrastructure as code and Ansible automation.

## Description

This repository contains a complete monitoring stack built with Terraform and Ansible. The infrastructure is designed to run in a multi-AZ AWS environment and uses enterprise best practices such as remote state in S3, DynamoDB locking, reusable Terraform modules, and Ansible roles.

Output:
![Project Structure](https://chatgpt.com/c/screenshots/project_structure.png)

## Use Case

This solution is intended for teams that need a resilient observability platform in AWS. It provides a production-style monitoring stack where Grafana is fronted by an ALB, supports autoscaling, and stores shared dashboards and plugins on EFS.

Output:
![Backend Configuration](https://chatgpt.com/c/screenshots/backend_configuration.png)

## Problem Statement

Set up an enterprise-ready monitoring environment that separates network, compute, storage, and automation concerns. The goal is to build an AWS architecture that is secure, scalable, and testable, while keeping the deployment repeatable with Terraform and Ansible.

Output:
![VPC Infrastructure](https://chatgpt.com/c/screenshots/vpc_infrastructure.png)

## Architecture Overview

The stack is organized as follows:

```
Internet
│
▼
ALB
│
▼
Grafana ASG
(Private Subnets)
│
▼
Shared EFS

---
Prometheus Primary
Prometheus Replica

---
Bastion Host

---
S3 Backend + DynamoDB Locking
```

- Public traffic enters through an Application Load Balancer.
- Grafana instances live in private subnets and scale with an Auto Scaling Group.
- Grafana uses a shared Amazon EFS filesystem for storage persistence.
- Prometheus runs as a primary and a replica for redundancy.
- A bastion host provides secure access into the private network.
- Terraform state is persisted in S3 with DynamoDB state locking.

Output:
![Public Private Subnets](https://chatgpt.com/c/screenshots/subnets.png)

## Implementation Steps

1. Build the Terraform bootstrap resources for remote state.
   Output:
   ![Terraform Init](https://chatgpt.com/c/screenshots/terraform_init.png)
2. Deploy the main infrastructure with reusable modules.
   Output:
   ![Terraform Plan](https://chatgpt.com/c/screenshots/terraform_plan.png)
3. Configure security groups for the ALB, bastion, Grafana, Prometheus, and EFS.
   Output:
   ![Security Groups](https://chatgpt.com/c/screenshots/security_groups.png)
4. Deploy Grafana ASG in private subnets behind the ALB.
   Output:
   ![Grafana Auto Scaling Group](https://chatgpt.com/c/screenshots/grafana_asg.png)
5. Create shared Amazon EFS mount targets for Grafana.
   Output:
   ![EFS Mount Targets](https://chatgpt.com/c/screenshots/efs_mount_targets.png)
6. Deploy Prometheus servers in separate AZs with EBS-backed storage.
   Output:
   ![Prometheus Setup](https://chatgpt.com/c/screenshots/prometheus_setup.png)
7. Use Ansible to install and configure Grafana, Prometheus, and Node Exporter.
   Output:
   ![Ansible Playbook](https://chatgpt.com/c/screenshots/ansible_playbook.png)
8. Verify the stack with Terraform validation and Ansible syntax checks.
   Output:
   ![Terraform Validate](https://chatgpt.com/c/screenshots/terraform_validate.png)

Output:
![Terraform Apply](https://chatgpt.com/c/screenshots/terraform_apply.png)

## Terraform Project Structure

```text
terraform-ansible/terraform-monitoring-stack/
├── backend.tf
├── main.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── variables.tf
└── modules/
    ├── alb/
    ├── autoscaling/
    ├── ec2/
    ├── efs/
    ├── security-group/
    └── vpc/
```

- `backend.tf`: S3 backend configuration.
- `main.tf`: root module wiring and module calls.
- `outputs.tf`: infrastructure outputs such as ALB DNS and EFS ID.
- `variables.tf`: centralized input variables and validation.
- `modules/`: reusable Terraform modules per component.

Output:
![Target Group](https://chatgpt.com/c/screenshots/target_group.png)

## Backend Configuration

The backend is configured to keep state remote and safe:

- S3 bucket stores the Terraform state file.
- DynamoDB table prevents concurrent apply operations.
- Encryption is enabled for S3 state.

This is important because remote state avoids local state drift and supports team collaboration.

Output:
![Terraform Outputs](https://chatgpt.com/c/screenshots/terraform_outputs.png)

Output:
![Backend Configuration](https://chatgpt.com/c/screenshots/backend_configuration.png)

## VPC Setup

The VPC is created with two public and two private subnets across AZs.

- Public subnets host the bastion and NAT gateway.
- Private subnets host Grafana and Prometheus instances.
- A NAT gateway enables outbound internet access for private instances.

This design isolates production monitoring traffic while allowing updates and downloads from the internet.

Output:
![VPC Infrastructure](https://chatgpt.com/c/screenshots/vpc_infrastructure.png)

Output:
![Public Private Subnets](https://chatgpt.com/c/screenshots/subnets.png)

## Security Groups

The security model separates access by role:

- ALB security group allows inbound HTTP from the internet.
- Bastion security group allows SSH only from a trusted CIDR.
- Monitoring security group allows Grafana, Prometheus, Node Exporter, and EFS traffic inside the VPC.

This keeps the monitoring stack accessible only through the ALB and bastion host.

Output:
![Security Groups](https://chatgpt.com/c/screenshots/security_groups.png)

## ALB Setup

The Application Load Balancer exposes Grafana to the internet.

- It is internet-facing.
- It routes HTTP traffic to the Grafana target group.
- Grafana instances live in private subnets and are not directly public.

Using an ALB allows the stack to scale and keeps the web tier separate from compute.

Output:
![Application Load Balancer](https://chatgpt.com/c/screenshots/alb_setup.png)

## Grafana Auto Scaling

Grafana is deployed in an Auto Scaling Group with a launch template.

- Grafana instances are launched in private subnets.
- The ASG can scale based on desired capacity.
- The target group connects the instances to the ALB.

This gives the monitoring dashboard redundancy and better availability.

Output:
![Launch Template](https://chatgpt.com/c/screenshots/launch_template.png)

Output:
![Grafana Auto Scaling Group](https://chatgpt.com/c/screenshots/grafana_asg.png)

## Shared EFS Setup

Amazon EFS is used for shared storage across Grafana instances.

- EFS filesystem is deployed in the private network.
- Mount targets are created for each private subnet.
- Grafana uses EFS for dashboard persistence and plugins.

Shared EFS makes the Grafana cluster stateful while still allowing horizontal scaling.

Output:
![EFS File System](https://chatgpt.com/c/screenshots/efs_setup.png)

Output:
![EFS Mount Targets](https://chatgpt.com/c/screenshots/efs_mount_targets.png)

## Prometheus Setup

Prometheus is deployed as a primary and a replica.

- Both instances run in private subnets.
- Each uses an encrypted EBS volume for local storage.
- An IAM role allows EC2 discovery if needed.

This setup provides basic redundancy and keeps metrics collection within the VPC.

Output:
![Prometheus Setup](https://chatgpt.com/c/screenshots/prometheus_setup.png)

Output:
![Prometheus Replica](https://chatgpt.com/c/screenshots/prometheus_replica.png)

## Bastion Host

The bastion host is placed in a public subnet to provide secure SSH access into the private network. It is the only host allowed to connect to Grafana and Prometheus over SSH.

Output:
![Bastion Host](https://chatgpt.com/c/screenshots/bastion_host.png)

## Ansible Roles

The Ansible configuration is organized into reusable roles:

- `common`: installs base utilities.
- `security`: optional firewall configuration.
- `node_exporter`: installs Node Exporter on monitoring hosts.
- `prometheus`: deploys Prometheus and service configuration.
- `efs`: mounts Grafana EFS and ensures file ownership.
- `grafana`: installs and configures Grafana.

This makes automation easier to maintain and reuse across environments.

Output:
![Ansible Roles](https://chatgpt.com/c/screenshots/ansible_roles.png)

## Terraform → Ansible Handoff

After Terraform deploys the infrastructure, Ansible is used for software configuration.

1. Run Terraform to create the stack and outputs.
2. Export the EFS filesystem ID from Terraform.
3. Pass the value to Ansible when executing the playbook.

Example:

```bash
cd terraform-ansible/terraform-monitoring-stack
terraform init
terraform apply -auto-approve
cd ansible-monitoring-stack
export GRAFANA_EFS_ID="$(terraform output -raw efs_id)"
ansible-playbook -i inventory/aws_ec2.yml site.yml -e grafana_efs_file_system_id="$GRAFANA_EFS_ID"
```

This ensures the Grafana role has the correct EFS mount target before configuration.

Output:
![Ansible Inventory](https://chatgpt.com/c/screenshots/ansible_inventory.png)

Output:
![Ansible Playbook](https://chatgpt.com/c/screenshots/ansible_playbook.png)

## Terraform Commands

Use these commands for the main stack:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

If you change backend settings or modules, rerun `terraform init` before planning.

Output:
![Terraform Init](https://chatgpt.com/c/screenshots/terraform_init.png)

Output:
![Terraform Validate](https://chatgpt.com/c/screenshots/terraform_validate.png)

Output:
![Terraform Plan](https://chatgpt.com/c/screenshots/terraform_plan.png)

Output:
![Terraform Apply](https://chatgpt.com/c/screenshots/terraform_apply.png)

## Ansible Playbook Execution

Install dependencies first:

```bash
python3 -m pip install --user ansible-core ansible-lint boto3 botocore
ansible-galaxy collection install amazon.aws ansible.posix community.general
```

Then run Ansible:

```bash
cd terraform-ansible/terraform-monitoring-stack/ansible-monitoring-stack
ansible-playbook -i inventory/aws_ec2.yml site.yml -e grafana_efs_file_system_id="$GRAFANA_EFS_ID"
```

This automates installation and configuration of Grafana, Prometheus, and Node Exporter.

Output:
![Ansible Playbook](https://chatgpt.com/c/screenshots/ansible_playbook.png)

## Verification Steps

Verify the infrastructure with these checks:

- `terraform validate`
- `terraform plan`
- `ansible-playbook --syntax-check site.yml`
- `ansible-lint site.yml`

For a deployed stack, confirm:

- ALB DNS resolves in the browser.
- Grafana is reachable on port 3000.
- Prometheus targets are healthy.
- EFS is mounted on Grafana instances.

Output:
![Final Verification](https://chatgpt.com/c/screenshots/verification.png)

## Jenkins CI/CD Setup & Manual Deployment

This stack can be deployed either automatically via a CI/CD pipeline or manually using the CLI:

* **CI/CD Pipeline (Jenkins)**: Refer to the [Jenkins Setup & Execution Guide](file:///d:/AWS/Assignment-05/docs/jenkins-setup-guide.md) for details on setting up credentials, configuring pipeline parameters, and triggering downstream tasks.
* **Manual Deployment (CLI)**: Refer to the [Manual CLI Deployment & Configuration Guide](file:///d:/AWS/Assignment-05/docs/manual-deployment-guide.md) for step-by-step terminal instructions, command logs, and variable overrides.

## Grafana Dashboard

Once Grafana is running, you can log in and add dashboards.

- Use the default Grafana admin credentials from the Ansible role.
- Create dashboards for Prometheus metrics, server health, and cluster status.

Output:
![Grafana Dashboard](https://chatgpt.com/c/screenshots/grafana_dashboard.png)

## Prometheus Targets

Prometheus should monitor:

- localhost on each Prometheus server
- Node Exporter on Grafana and Prometheus hosts

The current setup supports EC2 discovery and static target configuration.

Output:
![Prometheus Targets](https://chatgpt.com/c/screenshots/prometheus_targets.png)

## What I Learned

- Using remote Terraform state prevents drift and supports team use.
- Structuring infrastructure with modules keeps the code reusable and easier to manage.
- Private subnets with an ALB protect Grafana from direct exposure.
- EFS is a practical shared storage option for stateful clustered applications.
- Ansible roles help separate package installation, service configuration, and mount management.
- Combining Terraform and Ansible gives infrastructure and configuration a clean handoff.

Output:
![AWS Infrastructure](https://chatgpt.com/c/screenshots/aws_infrastructure.png)

- Create dashboards for the Prometheus metrics.
- Store dashboards on EFS so they remain available across instances.

## Prometheus Targets

Prometheus should monitor:

- localhost on each Prometheus server
- Node Exporter on Grafana and Prometheus hosts

The current setup supports EC2 discovery and static target configuration.

## What I Learned

- Using remote Terraform state prevents drift and supports team use.
- Structuring infrastructure with modules keeps the code reusable and easier to manage.
- Private subnets with an ALB protect Grafana from direct exposure.
- EFS is a practical shared storage option for stateful clustered applications.
- Ansible roles help separate package installation, service configuration, and mount management.
- Combining Terraform and Ansible gives infrastructure and configuration a clean handoff.

![Project Summary](https://chatgpt.com/c/screenshots/project_summary.png)
