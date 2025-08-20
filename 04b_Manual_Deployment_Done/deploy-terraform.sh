#!/bin/bash
set -e

# Load environment variables
source ./load-env.sh

echo "🏗️ Deploying infrastructure with Terraform..."

cd terraform_code

# Create input.tfvars from environment variables
echo "📄 Creating Terraform variables file..."
cat > input.tfvars << EOF
project_id = "$PROJECT_ID"
region = "$REGION"
backend_service_name = "$BACKEND_SERVICE_NAME"
frontend_service_name = "$FRONTEND_SERVICE_NAME"
bucket_name = "$BUCKET_NAME"
secret_name = "$SECRET_NAME"
min_instances = $MIN_INSTANCES
max_instances = $MAX_INSTANCES
EOF

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan -var-file="input.tfvars"

# Apply infrastructure (with confirmation)
echo "⚠️ About to deploy infrastructure. Press Enter to continue or Ctrl+C to abort..."
read

terraform apply -var-file="input.tfvars" -auto-approve

# Get outputs
echo "📋 Infrastructure Outputs:"
terraform output

cd ..

echo "✅ Infrastructure deployment complete"
