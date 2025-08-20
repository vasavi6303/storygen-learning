#!/bin/bash
set -e

source ./deploy-env.sh

echo "🏗️ Deploying infrastructure with Terraform..."

cd terraform_code

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="input.tfvars"

# Apply infrastructure (you may want to review the plan first)
echo "⚠️ About to deploy infrastructure. Press Enter to continue or Ctrl+C to abort..."
read

terraform apply -var-file="input.tfvars" -auto-approve

# Get outputs
echo "📋 Infrastructure Outputs:"
terraform output

cd ..

echo "✅ Infrastructure deployment complete"
