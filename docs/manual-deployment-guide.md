# Manual CLI Deployment & Configuration Guide

This guide details how to manually deploy the enterprise monitoring stack using the CLI from your local system (such as WSL/Ubuntu, Linux, or macOS).

---

## 1. Prerequisites

Before beginning, ensure your local system is set up with the following:

### AWS CLI & Credentials
1. **Install the AWS CLI**: Follow the official guide to install `aws`.
2. **Configure Credentials**:
   ```bash
   aws configure
   ```
   Provide your AWS Access Key ID, Secret Access Key, region (`ap-south-1`), and output format.
3. **SSH Key Pair**:
   * Ensure you have a key pair created in AWS AP-SOUTH-1 named `assignment-6`.
   * Save the corresponding private key at `~/.ssh/assignment-6.pem` and set the correct permissions:
     ```bash
     chmod 400 ~/.ssh/assignment-6.pem
     ```

### Local CLI Tools
1. **Terraform**: Install Terraform version `>= 1.0.0`.
2. **Python 3 & pip**:
   ```bash
   sudo apt update
   ```
   ```bash
   sudo apt install python3 python3-pip -y
   ```
3. **Ansible**:
   ```bash
   python3 -m pip install --user ansible-core botocore boto3
   ```
4. **Ansible Collections**:
   ```bash
   ansible-galaxy collection install amazon.aws ansible.posix community.general
   ```

---

## 2. Step 1: Bootstrapping the Backend (S3 & DynamoDB)

We use an S3 bucket and DynamoDB table to maintain a secure remote state and enable locking.

1. Navigate to the bootstrap directory:
   ```bash
   cd terraform-ansible/terraform-monitoring-stack/bootstrap
   ```
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review and apply the configuration to create the S3 bucket (`monitoring-stack-dev-state`) and DynamoDB table (`monitoring-stack-dev-lock`):
   ```bash
   terraform apply -auto-approve
   ```

---

## 3. Step 2: Provisioning the Main Infrastructure Stack

1. Navigate to the main Terraform directory:
   ```bash
   cd ../terraform
   ```
2. Initialize Terraform (this installs modules and configures the S3 remote backend):
   ```bash
   terraform init
   ```
3. Generate and verify the provisioning plan for the `dev` environment:
   ```bash
   terraform plan -var environment=dev -out=tfplan
   ```
4. Apply the plan to provision the VPC, Subnets, Bastion Host, Load Balancer, EFS File System, and Auto Scaling Group:
   ```bash
   terraform apply -auto-approve tfplan
   ```
5. Note the outputs of the deployment. You can query them anytime using:
   ```bash
   terraform output
   ```
   Example outputs:
   ```text
   alb_dns_name       = "monitoring-dev-alb-XXXXXXXXX.ap-south-1.elb.amazonaws.com"
   bastion_public_ip  = "13.207.41.221"
   efs_dns_name       = "fs-XXXXXXXXX.efs.ap-south-1.amazonaws.com"
   efs_id             = "fs-XXXXXXXXX"
   ```

---

## 4. Step 3: Configuring the Monitoring Services with Ansible

Once the infrastructure is up, use Ansible to configure the Bastion and private EC2 instances. Ansible dynamically discovers the instances using the `amazon.aws.aws_ec2` inventory plugin.

1. Navigate to the Ansible project directory:
   ```bash
   cd ../../ansible-monitoring-stack
   ```
2. Obtain the **Bastion IP** and **EFS ID** from the Terraform outputs. You can query them dynamically:
   ```bash
   # Make sure you are referencing the correct path to the terraform folder when running this from the Ansible folder
   export BASTION_IP=$(terraform -chdir=../terraform-monitoring-stack/terraform output -raw bastion_public_ip)
   export EFS_ID=$(terraform -chdir=../terraform-monitoring-stack/terraform output -raw efs_id)
   ```
3. Perform a syntax check on the playbook:
   ```bash
   ansible-playbook --syntax-check site.yml
   ```
4. Execute the Ansible playbook, passing the dynamic values as extra variables:
   ```bash
   ansible-playbook -i inventory/aws_ec2.yml site.yml \
     -e "bastion_ip=$BASTION_IP" \
     -e "grafana_efs_file_system_id=$EFS_ID" \
     -e "ansible_ssh_private_key_file=~/.ssh/assignment-6.pem"
   ```
   * *Note*: If Ansible has trouble discovering the instances immediately, wait a few seconds for the EC2 Auto Scaling instances to boot completely and pass their initialization checks before retrying.

---

## 5. Step 4: Verification

### Active Target Verification
Confirm the health status of the targets through the AWS EC2 Application Load Balancer Target Group Console. The targets should report as **Healthy** (port 3000).

### Browser Verification
Open your web browser and navigate to the ALB DNS endpoint:
```text
http://<alb_dns_name>
```
* You should be redirected to the Grafana login page.
* Log in using the default credentials (`admin`/`admin`).

---

## 6. Step 5: Teardown & Clean Up

To tear down and delete all provisioned infrastructure securely, you can run the automated cleanup script or execute the commands manually.

### Option A: Automated Cleanup (Recommended)
We have provided a self-contained teardown script at the root of the project: [destroy.sh](file:///d:/AWS/Assignment-05/destroy.sh).
Run the following command from the root of the repository in WSL/Ubuntu:
```bash
bash destroy.sh
```
This script will automatically:
1. Run `terraform destroy` on the main infrastructure stack.
2. Modify `s3.tf` to set `prevent_destroy = false`.
3. Run `terraform destroy` on the bootstrap resources.
4. Execute an inline python block using `boto3` to empty and delete the versioned S3 bucket and the DynamoDB locking table.
5. Print the final AWS environment health checks.

### Option B: Manual Execution
If you prefer to clean up manually:
1. Navigate to the main Terraform directory:
   ```bash
   cd ../terraform-monitoring-stack/terraform
   ```
2. Destroy the main stack:
   ```bash
   terraform destroy -auto-approve -var environment=dev
   ```
3. Navigate to the bootstrap directory:
   ```bash
   cd ../bootstrap
   ```
4. Temporarily disable `prevent_destroy = true` in `s3.tf` if you want to delete the state bucket, then run:
   ```bash
   terraform destroy -auto-approve
   ```

