# Ansible Monitoring Stack

This directory contains the Ansible monitoring stack for the Terraform monitoring infrastructure.

## Requirements

- `ansible-core`
- Python 3
- `ansible-lint`
- `boto3`
- `botocore`
- `amazon.aws` Ansible collection
- `ansible.posix` collection (for `firewalld` support)

## Install dependencies

```bash
python3 -m pip install --user ansible-core ansible-lint boto3 botocore
ansible-galaxy collection install amazon.aws ansible.posix
```

If `pip` is not available, install it via your OS package manager.

## Terraform → Ansible Handoff

Before running the Ansible playbook, create the Terraform infrastructure and pass the EFS file system ID into the Grafana role.

Example:

```bash
cd ../
terraform init
terraform apply -auto-approve
cd ansible-monitoring-stack
export GRAFANA_EFS_ID="$(terraform output -raw efs_id)"
ansible-playbook -i inventory/aws_ec2.yml site.yml -e grafana_efs_file_system_id="$GRAFANA_EFS_ID"
```

Alternatively, write the output value into `group_vars/all.yml`:

```yaml
grafana_efs_file_system_id: "<efs_id>"
```

This ensures the Grafana role can mount EFS before it starts.

## Inventory

This repository uses one primary inventory option:

- `inventory/aws_ec2.yml` — dynamic AWS EC2 inventory using the `amazon.aws.aws_ec2` plugin

### Using dynamic AWS inventory

```bash
ansible-playbook -i inventory/aws_ec2.yml site.yml
```

If you need a manual fallback, keep the inventory file in place and update it with real host values, but the preferred path is the dynamic AWS inventory.

## Notes

- `grafana_efs_file_system_id` must be set before running the Grafana role.
- Firewall support is disabled by default in `roles/security`.
