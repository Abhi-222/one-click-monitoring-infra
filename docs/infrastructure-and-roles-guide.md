# Enterprise Monitoring Stack: Infrastructure & Roles Reference Guide

This guide provides a detailed technical breakdown of the monitoring infrastructure components and configuration roles configured in this repository.

---

## ☁️ AWS Infrastructure Architecture

The infrastructure is written in modular Terraform code (`terraform-monitoring-stack/terraform`) to provision a highly secure, scalable, and isolated cloud network on AWS.

```
                  [ Admin / User ]
                         │
                         ▼
        [ Public Subnet: Internet Gateway (IGW) ]
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
   [ Port 80 ]                       [ Port 22 ]
[ Load Balancer (ALB) ]             [ Bastion Host ]
        │                                 │
        │ (Forward Port 3000)             │ (ProxyTunnel SSH)
        ▼                                 ▼
┌────────────────────────────────────────────────────────┐
│ Private Subnets: Monitoring Security Group             │
│                                                        │
│  ┌──────────────┐      ┌──────────────┐      ┌──────┐  │
│  │   Grafana    │      │  Prometheus  │      │ Node │  │
│  │  (Port 3000) │      │  (Port 9090) │      │ Exptr│  │
│  └──────┬───────┘      └──────┬───────┘      └──────┘  │
│         │ (NFS Mount)         │ (TSDB Mount)           │
│         ▼                     ▼                        │
│  [ Shared EFS ]         [ Dedicated EBS ]              │
└────────────────────────────────────────────────────────┘
```

### 1. Network Layer (VPC & Subnets)
* **What**: A custom Virtual Private Cloud (VPC) with a `10.0.0.0/16` CIDR block divided into two Public Subnets and two Private Subnets across separate Availability Zones (AZs) for high availability.
* **How**:
  - **Internet Gateway (IGW)**: Directs external inbound HTTP requests to the Application Load Balancer and handles Bastion SSH jumps.
  - **NAT Gateway (NAT-GW)**: Placed in the public subnet to allow private instances outbound access (e.g. download repositories, fetch package updates) without assigning public IPs to them.
  - **Route Tables**: Separate route tables segregate network traffic; private subnets route outbound traffic solely through the NAT Gateway.

### 2. Traffic Control & Load Balancing (ALB)
* **What**: An internet-facing Application Load Balancer (ALB) exposing Grafana dashboards to port `80`.
* **How**:
  - The ALB forwards HTTP traffic to the Grafana target group on port `3000`.
  - Health checks query the target instances at `/` every 30 seconds to ensure high availability.

### 3. Compute & Scaling (EC2, Bastion & ASG)
* **What**: A hybrid compute layer consisting of an Auto Scaling Group (ASG) and a secure Jump Box (Bastion).
* **How**:
  - **Bastion Host**: Deployed in a public subnet to act as the single secure entry point. Administrators tunnel SSH traffic through it to configure private instances.
  - **Grafana ASG**: Deployed in private subnets utilizing a Launch Template (`monitoring-dev-lt`). It scales dynamically between a minimum of 1 and a maximum of 2 instances.
  - **Security Groups**:
    - **ALB SG**: Allows inbound HTTP traffic from `0.0.0.0/0`.
    - **Bastion SG**: Restricts inbound SSH strictly to trusted IP networks.
    - **Monitoring SG**: Restricts port `3000` to the ALB security group, port `22` to the Bastion security group, and internal metric ports (`9090`, `9100`, `2049`) within the VPC CIDR boundary.

### 4. Storage & Persistence (EFS & EBS)
* **What**: Persistent data architectures separating shared application configurations from primary metrics.
* **How**:
  - **Amazon EFS**: A shared filesystem mounted dynamically to Grafana targets over the network (port `2049`). This preserves user dashboards, plugins, and configuration states across instance lifecycle operations (destroys, scales).
  - **Amazon EBS**: A dedicated 50GB `gp3` block device mapped to `/dev/xvdb` and mounted locally to `/prometheus-data`. This ensures that metrics stored inside the Prometheus TSDB (Time Series Database) are persisted locally without inflating the OS root partition (`/dev/xvda`).

### 5. Identity & Access Management (IAM)
* **What**: IAM Role-based authentication to grant EC2 instances permissions to query AWS metadata.
* **How**:
  - Defines the instance profile `monitoring-dev-ec2-monitoring-profile`.
  - Attaches a policy permitting `ec2:DescribeInstances`, `ec2:DescribeTags`, and `ec2:DescribeAvailabilityZones`. This allows Prometheus to run dynamic EC2 Service Discovery to scrape active nodes without using hardcoded access keys.

---

## 🛠️ Ansible Configuration Roles

Configuration management (`terraform-ansible/ansible-monitoring-stack`) uses Ansible roles to set up the software stack across VPC instances dynamically.

### 1. Dynamic Inventory (`aws_ec2`)
* **What**: Ansible utilizes the `amazon.aws.aws_ec2` plugin to construct the host list by querying active AWS resources.
* **How**:
  - It filters instances containing tag `Project: Monitoring Infrastructure` and environment `dev`.
  - It dynamically groups them: instances with tag `Role: bastion` are placed under the `bastion` group, and instances with `Role: monitoring` are grouped under the `monitoring` group.
  - Generates the dynamic SSH `ansible_host` targeting public IPs for the Bastion and private IPs for monitoring nodes.

### 2. Host Configuration Roles
* **`common`**: Configures base operating system requirements. Installs default utilities (e.g. `curl`, `git`, package tools), updates repositories, and verifies network endpoints.
* **`security`**: Hardens system security. Configures host firewall options and manages standard access controls.
* **`node_exporter`**: Downloads and registers Prometheus Node Exporter as a systemd service running on port `9100` to expose system metrics (CPU, Memory, Disk IO).
* **`prometheus`**:
  - Deploys the Prometheus server binary to private monitoring nodes.
  - Mounts the local EBS volume to `/prometheus-data`.
  - Templates `prometheus.yml` to automatically scrape localhost metrics on port `9090`, and registers the dynamic AWS EC2 discovery configuration to scrape active Node Exporter endpoints on port `9100`.
* **`alertmanager`**: Deploys Alertmanager on private hosts to receive alert alerts on port `9093` from Prometheus and handle alert routing and notification.
* **`efs`**: Installs AWS EFS utilities (`amazon-efs-utils`), creates the directory mount point, and configures the `/etc/fstab` table to persist the EFS mount to `/var/lib/grafana` securely.
* **`grafana`**: Installs Grafana from official repositories, updates `/etc/grafana/grafana.ini` with internal configuration details, and registers the server as a systemd daemon running on port `3000`.

---

## 🔄 Pipeline Orchestration Flow

CI/CD operations are unified under a **Jenkins Shared Library** configuration to keep deployment pipelines clean and secure:

```
[ Developer / Admin ]
         │
         │ (1. Parameters input)
         ▼
[ Upstream Job: Jenkinsfile.infra ] ───► (2. runTerraform shared step)
         │                                       │
         │                                       ▼
         │                              [ S3 / DynamoDB State ]
         │                                       │ (Init/Apply)
         │                                       ▼
         │                               [ AWS VPC & VMs ]
         │
         │ (3. Passes: BASTION_IP & EFS_ID parameters)
         ▼
[ Downstream Job: Jenkinsfile.ansible ] ──► (4. runAnsible shared step)
                                                 │
                                                 ▼
                                        [ Ansible Playbook ]
                                                 │ (SSH ProxyTunnel)
                                                 ▼
                                      [ Configuration complete ]
```

1. **Step 1: Input**: Admin triggers the upstream job, providing inputs (`ACTION`: apply/destroy, `ENVIRONMENT`, and `NOTIFICATION_EMAIL`).
2. **Step 2: Provisioning**: The pipeline calls `runTerraform(action, env, dir)` from the shared library. Terraform initializes, locks backend states in S3/DynamoDB, and provisions the network and compute resources.
3. **Step 3: Hand-Off**: Once complete, the upstream job queries the Terraform outputs `bastion_public_ip` and `efs_id` and triggers the downstream pipeline, passing these variables.
4. **Step 4: Configuration**: The downstream job pulls the repo and invokes `runAnsible(bastionIp, efsId, env, dir, sshKeyId)`. It installs target dependencies, validates playbook syntax, loads the SSH private key securely, and launches Ansible.
5. **Step 5: Access**: Ansible uses the dynamic ProxyCommand configuration to tunnel SSH commands through the Bastion's public IP to configure Grafana, Prometheus, EFS mounts, and Alertmanager on private hosts.
6. **Step 6: Notifications**: Both jobs catch execution status and invoke Jenkins `mail` blocks to alert administrators on build status updates.
