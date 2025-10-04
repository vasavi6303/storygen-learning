#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Load environment variables
source load-env.sh

echo "Deploying infrastructure with Terraform..."

# 1. Navigate to the Terraform directory
cd terraform_code

# 2. Initialize Terraform
terraform init

# 3. Apply Terraform configuration
terraform apply -auto-approve \
  -var="project_id=$GCP_PROJECT_ID" \
  -var="region=$GCP_REGION" \
  -var="backend_image=$BACKEND_DOCKER_IMAGE" \
  -var="frontend_image=$FRONTEND_DOCKER_IMAGE" \
  -var="backend_service_name=$BACKEND_SERVICE_NAME" \
  -var="frontend_service_name=$FRONTEND_SERVICE_NAME"


# 4. Get the output URLs
BACKEND_URL=$(terraform output -raw backend_service_url)
FRONTEND_URL=$(terraform output -raw frontend_service_url)

echo "Infrastructure deployed successfully."
echo "Backend service URL: $BACKEND_URL"
echo "Frontend service URL: $FRONTEND_URL"
