#!/bin/bash
set -e

echo "🚀 StoryGen Complete Deployment Pipeline"
echo "========================================"

# Check if .env file exists
if [ ! -f "../.env" ]; then
    echo "❌ Environment file not found: ../.env"
    echo ""
    echo "Please create a .env file in the parent directory with your configuration."
    echo "Required variables:"
    echo "  GOOGLE_GENAI_USE_VERTEXAI=FALSE"
    echo "  GOOGLE_API_KEY=your_google_api_key"
    echo "  GOOGLE_CLOUD_PROJECT_ID=your_project_id"
    echo "  GENMEDIA_BUCKET=your_bucket_name"
    echo "  GITHUB_USERNAME=your_github_username"
    echo "  GITHUB_REPO=your_repo_name"
    echo "  SECRET_MANAGER=your_secret_name"
    echo ""
    echo "Optional variables (with defaults):"
    echo "  REGION=us-central1"
    echo "  BACKEND_SERVICE_NAME=genai-backend"
    echo "  FRONTEND_SERVICE_NAME=genai-frontend"
    echo "  And more..."
    exit 1
fi

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ terraform not found. Please install Terraform."
    exit 1
fi

# Authenticate
echo "🔐 Checking authentication..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 || {
    echo "❌ No active gcloud authentication found."
    echo "Please run: gcloud auth login && gcloud auth application-default login"
    exit 1
}

# Load environment variables
source ./load-env.sh

echo ""
echo "🏗️ Starting deployment pipeline..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Step 1: Setup Prerequisites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Setting up prerequisites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x setup-prerequisites.sh
./setup-prerequisites.sh

# Step 2: Deploy Infrastructure
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Deploying infrastructure with Terraform..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x deploy-terraform.sh
./deploy-terraform.sh

# Step 3: Deploy Backend
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Deploying backend..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x deploy-backend-new.sh
./deploy-backend-new.sh

# Step 4: Deploy Frontend
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Deploying frontend..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x deploy-frontend-new.sh
./deploy-frontend-new.sh

echo ""
echo "🎉 Deployment Complete!"
echo "======================="

if [ -f "./backend-url.env" ]; then
    source ./backend-url.env
    echo "🔗 Backend URL: $BACKEND_URL"
fi

FRONTEND_URL=$(gcloud run services describe "$FRONTEND_SERVICE_NAME" \
    --platform=managed \
    --region="$REGION" \
    --format="value(status.url)" \
    --project="$PROJECT_ID" 2>/dev/null || echo "Not deployed")

echo "🌐 Frontend URL: $FRONTEND_URL"
echo ""
echo "📋 Next Steps:"
echo "1. Visit your application at the Frontend URL"
echo "2. Test the story generation functionality"
echo "3. Monitor the application using Cloud Run logs:"
echo "   gcloud logs tail --filter=\"resource.type=cloud_run_revision\" --project=$PROJECT_ID"
echo ""
echo "🔧 Useful Commands:"
echo "   Update backend:  ./deploy-backend-new.sh"
echo "   Update frontend: ./deploy-frontend-new.sh"
echo "   View logs:       gcloud logs tail --filter=\"resource.type=cloud_run_revision\" --project=$PROJECT_ID"
echo "   Cleanup:         cd terraform_code && terraform destroy -var-file=input.tfvars"
