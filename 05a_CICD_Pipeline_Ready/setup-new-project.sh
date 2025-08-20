#!/bin/bash

# StoryGen Project Setup Script
# This script helps you configure StoryGen for a new Google Cloud project

set -e

echo "🚀 StoryGen Project Setup"
echo "========================"
echo ""

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    read -p "$prompt [$default]: " input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# Get project configuration
echo "📋 Project Configuration"
echo "========================"

prompt_with_default "Google Cloud Project ID" "your-project-id" "PROJECT_ID"
prompt_with_default "Deployment Region" "us-central1" "REGION"
prompt_with_default "Backend Service Name" "genai-backend" "BACKEND_SERVICE"
prompt_with_default "Frontend Service Name" "genai-frontend" "FRONTEND_SERVICE"
prompt_with_default "Artifact Repository Name" "storygen-repo" "ARTIFACT_REPO"
prompt_with_default "Storage Bucket Name" "${PROJECT_ID}-story-images" "BUCKET_NAME"

echo ""
echo "📋 Configuration Summary:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Backend Service: $BACKEND_SERVICE"
echo "  Frontend Service: $FRONTEND_SERVICE"
echo "  Artifact Repository: $ARTIFACT_REPO"
echo "  Bucket Name: $BUCKET_NAME"
echo ""

read -p "Is this configuration correct? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled. Please run the script again."
    exit 1
fi

# Create config.env file
echo "📝 Creating config.env file..."
cat > config.env << EOF
# StoryGen Configuration for Project: $PROJECT_ID
# Generated on $(date)

# Required: Your Google Cloud Project ID
PROJECT_ID=$PROJECT_ID

# Optional: Deployment region (default: us-central1)
REGION=$REGION

# Optional: Service names (defaults provided)
BACKEND_SERVICE_NAME=$BACKEND_SERVICE
FRONTEND_SERVICE_NAME=$FRONTEND_SERVICE

# Optional: Docker image names (defaults provided)
BACKEND_IMAGE_NAME=storygen-backend
FRONTEND_IMAGE_NAME=storygen-frontend

# Optional: Artifact Registry repository name (default: storygen-repo)
ARTIFACT_REPO=$ARTIFACT_REPO

# Optional: Cloud Storage bucket name (default: PROJECT_ID-story-images)
BUCKET_NAME=$BUCKET_NAME

# Optional: Secret Manager secret name (default: storygen-google-api-key)
SECRET_NAME=storygen-google-api-key

# Optional: Resource configurations (defaults provided)
BACKEND_MEMORY=2Gi
BACKEND_CPU=2
FRONTEND_MEMORY=1Gi
FRONTEND_CPU=1

# Optional: Scaling configuration
MIN_INSTANCES=0
MAX_INSTANCES=2
EOF

# Create Terraform variables file
echo "📝 Creating terraform_code/input.tfvars file..."
cat > terraform_code/input.tfvars << EOF
# Terraform Variables for StoryGen
# Generated on $(date)

# Required: Your Google Cloud Project ID
project_id = "$PROJECT_ID"

# Optional: Deployment region
region = "$REGION"

# Optional: Service names
backend_service_name = "$BACKEND_SERVICE"
frontend_service_name = "$FRONTEND_SERVICE"

# Optional: Bucket name for generated images
bucket_name = "$BUCKET_NAME"
EOF

echo "✅ Configuration files created successfully!"
echo ""

# Check if gcloud is configured
if command -v gcloud &> /dev/null; then
    echo "🔍 Checking Google Cloud configuration..."
    
    # Check if authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
        CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
        echo "✅ Authenticated as: $CURRENT_ACCOUNT"
        
        # Check current project
        CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "not-set")
        if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
            echo "⚠️ Current project: $CURRENT_PROJECT"
            read -p "Set project to $PROJECT_ID? (y/N): " set_project
            if [[ $set_project =~ ^[Yy]$ ]]; then
                gcloud config set project "$PROJECT_ID"
                echo "✅ Project set to $PROJECT_ID"
            fi
        else
            echo "✅ Current project: $PROJECT_ID"
        fi
        
        # Check billing
        if gcloud billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null | grep -q "True"; then
            echo "✅ Billing enabled for project $PROJECT_ID"
        else
            echo "⚠️ Billing not enabled for project $PROJECT_ID"
            echo "   Please enable billing in the Google Cloud Console:"
            echo "   https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
        fi
    else
        echo "⚠️ Not authenticated with gcloud"
        echo "   Run: gcloud auth login && gcloud auth application-default login"
    fi
else
    echo "⚠️ gcloud CLI not found"
    echo "   Install from: https://cloud.google.com/sdk/docs/install"
fi

echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "For CI/CD Deployment:"
echo "1. Set up Workload Identity Provider (see FORK_SETUP.md)"
echo "2. Configure GitHub repository variables:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - GCP_REGION: $REGION"
echo "   - BACKEND_SERVICE_NAME: $BACKEND_SERVICE"
echo "   - FRONTEND_SERVICE_NAME: $FRONTEND_SERVICE"
echo "3. Configure GitHub repository secrets:"
echo "   - WORKLOAD_IDENTITY_PROVIDER"
echo "   - GCP_SERVICE_ACCOUNT_EMAIL"
echo "   - GOOGLE_API_KEY"
echo "4. Push to main branch to trigger deployment"
echo ""
echo "For Manual Deployment:"
echo "1. Ensure gcloud is authenticated and billing is enabled"
echo "2. Get Google AI Studio API key from https://aistudio.google.com/"
echo "3. Run: ./deploy-complete.sh"
echo ""
echo "📁 Files Created:"
echo "  - config.env (environment configuration)"
echo "  - terraform_code/input.tfvars (Terraform variables)"
echo ""
echo "🎉 Setup complete! Your StoryGen is ready to deploy to project: $PROJECT_ID"
