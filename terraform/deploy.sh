#!/bin/bash
set -e

echo "=== Smart Financial Advisor — Deploy ==="
echo ""

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform not found"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws cli not found"; exit 1; }

# Check for tfvars
if [ ! -f terraform.tfvars ]; then
  echo "No terraform.tfvars found. Copying example..."
  cp terraform.tfvars.example terraform.tfvars
  echo "Please edit terraform.tfvars with your settings, then re-run."
  exit 1
fi

echo "Initializing Terraform..."
terraform init

echo ""
echo "Planning deployment..."
terraform plan -out=tfplan

echo ""
read -p "Apply this plan? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Deploying (~5-10 minutes)..."
terraform apply tfplan

echo ""
echo "=== Deployment Complete ==="
echo ""
terraform output
