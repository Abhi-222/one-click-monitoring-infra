# Infrastructure Cleanup and Fresh Terraform Plan

## Goal
The objective is to remove previously created AWS resources and then generate a fresh Terraform execution plan from the current state configuration before any re-deployment.

## 1. Confirm current Terraform state
1. Check the backend configuration and confirm the current state location.
2. Review the existing Terraform state to understand what resources were previously created.
3. Verify that the state is the source of truth for the current deployment record.

## 2. Destroy previously created AWS resources
1. Go to the main Terraform directory:
   - `terraform-ansible/terraform-monitoring-stack/terraform`
2. Run the exact cleanup commands:
   - `terraform init`
   - `terraform plan -destroy`
   - `terraform destroy -auto-approve`
3. Review the output to confirm that AWS resources are being removed.
4. After the destroy completes, verify that the AWS resources are no longer present.

## 3. Refresh the state and verify cleanup
1. Run:
   - `terraform state list`
2. Confirm the state is either empty or only reflects resources that should remain.
3. If needed, re-run:
   - `terraform refresh`
4. This confirms the state matches the current AWS reality.

## 4. Generate a fresh plan
1. Re-run the Terraform initialization if required:
   - `terraform init`
2. Run a fresh plan:
   - `terraform plan`
3. Save the plan output to a file for review:
   - `terraform plan -out=tfplan`
   - `terraform show -no-color tfplan > fresh-plan.txt`
4. Review the saved plan content to confirm that the infrastructure is being recreated exactly as expected.

## 5. Notes for this project
- The plan should be based on the actual Terraform configuration and current state.
- The generated inventory files should only be used after the infrastructure exists.
- Any placeholder values or old static inventory references should not be used for the final deployment.

## 6. Recommended next step
- After reviewing the saved fresh plan, proceed with:
  - `terraform apply tfplan`

