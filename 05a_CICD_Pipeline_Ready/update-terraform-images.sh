#!/bin/bash
set -e

source ./deploy-env.sh

echo "🔄 Updating Terraform configuration with actual container images..."

# Get the latest image digests
BACKEND_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${BACKEND_IMAGE_NAME}:latest"
FRONTEND_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${FRONTEND_IMAGE_NAME}:latest"

# Update main.tf with actual images and environment variables
cd terraform_code

# Create a backup
cp main.tf main.tf.backup

# Update backend container configuration
sed -i.tmp "s|\"container_image\" = \"us-docker.pkg.dev/cloudrun/container/hello\", \"container_name\" = \"backend-container\"|\"container_image\" = \"${BACKEND_IMAGE}\", \"container_name\" = \"backend-container\", \"env_vars\" = {\"GOOGLE_CLOUD_PROJECT\" = \"${PROJECT_ID}\", \"GOOGLE_CLOUD_PROJECT_ID\" = \"${PROJECT_ID}\", \"GENMEDIA_BUCKET\" = \"${BUCKET_NAME}\", \"GOOGLE_GENAI_USE_VERTEXAI\" = \"TRUE\"}|g" main.tf

# Update frontend container configuration  
sed -i.tmp "s|\"container_image\" = \"us-docker.pkg.dev/cloudrun/container/hello\", \"container_name\" = \"frontend-container\"|\"container_image\" = \"${FRONTEND_IMAGE}\", \"container_name\" = \"frontend-container\"|g" main.tf

# Clean up temp files
rm -f main.tf.tmp

echo "✅ Terraform configuration updated"
echo "📋 Review the changes in terraform_code/main.tf"
echo "🔄 Run 'terraform plan' and 'terraform apply' to update the infrastructure"

cd ..
