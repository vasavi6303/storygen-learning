#!/bin/bash
set -e

echo "🚀 StoryGen Complete Deployment"
echo "==============================="
echo ""
echo "This script will:"
echo "1. Set up prerequisites (APIs, Artifact Registry, Secrets)"
echo "2. Build and push Docker images"
echo "3. Deploy infrastructure with Terraform"
echo "4. Provide you with working application URLs"
echo ""

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
    echo "You can copy env.template from the root directory as a starting point."
    exit 1
fi

# Load and verify environment
source ./load-env.sh

echo ""
echo "🔍 Verifying configuration..."
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Bucket: $BUCKET_NAME"
echo ""

# Check required tools
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ terraform not found. Please install Terraform."
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &>/dev/null; then
    echo "❌ No active gcloud authentication found."
    echo "Please run: gcloud auth login && gcloud auth application-default login"
    exit 1
fi

echo "✅ All prerequisites look good!"
echo ""

# Confirm deployment
echo "⚠️ About to deploy StoryGen to project '$PROJECT_ID'."
echo "   This will create Cloud Run services, buckets, and other GCP resources."
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "🎯 Starting deployment pipeline..."
echo ""

# Check for existing resources that might cause conflicts
echo "🔍 Pre-deployment checks..."
if gsutil ls "gs://$BUCKET_NAME" &>/dev/null; then
    echo "✅ Existing bucket found: $BUCKET_NAME (will be imported)"
fi

if gcloud artifacts repositories describe "$ARTIFACT_REPO" --location="$REGION" --project="$PROJECT_ID" &>/dev/null 2>&1; then
    echo "✅ Existing Artifact Registry found: $ARTIFACT_REPO"
fi

echo ""

# Step 1: Setup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Setting up prerequisites..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x 01-setup.sh
./01-setup.sh

# Step 2: Build Images
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Building and pushing Docker images..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x 02-build-images.sh
./02-build-images.sh

# Step 3: Deploy Infrastructure
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Deploying infrastructure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x 03-deploy-infrastructure.sh
./03-deploy-infrastructure.sh

echo ""
echo "🎉 Deployment Complete!"
echo "======================="

if [ -f "deployment-urls.env" ]; then
    source deployment-urls.env
    echo ""
    echo "🌐 Your Application URLs:"
    echo "   Frontend: $FRONTEND_URL"
    echo "   Backend:  $BACKEND_URL"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Visit your application at: $FRONTEND_URL"
    echo "2. Test the story generation functionality"
    echo "3. Monitor logs: gcloud logs tail --filter=\"resource.type=cloud_run_revision\" --project=$PROJECT_ID"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   View logs:     gcloud logs tail --filter=\"resource.type=cloud_run_revision\" --project=$PROJECT_ID"
    echo "   Rebuild:       ./02-build-images.sh && ./03-deploy-infrastructure.sh"
    echo "   Cleanup:       cd terraform_code && terraform destroy"
fi

echo ""
echo "📝 All deployment files saved for future reference."
echo "✅ StoryGen is now running on Google Cloud!"
