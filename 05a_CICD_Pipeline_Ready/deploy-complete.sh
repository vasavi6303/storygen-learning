#!/bin/bash
set -e

echo "🚀 StoryGen Complete Deployment Pipeline"
echo "========================================"

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

# Set project
echo "⚙️ Setting up project configuration..."
gcloud config set project sdlc-468305

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    aiplatform.googleapis.com \
    storage.googleapis.com \
    secretmanager.googleapis.com \
    --project=sdlc-468305

# Step 1: Setup Secret
echo ""
echo "Step 1: Setting up secret for API key..."
chmod +x setup-secret.sh
./setup-secret.sh

# Step 2: Setup Artifact Registry
echo ""
echo "Step 2: Setting up Artifact Registry..."
chmod +x setup-artifact-registry.sh
./setup-artifact-registry.sh

# Step 3: Deploy Infrastructure
echo ""
echo "Step 3: Deploying infrastructure..."
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh

# Step 4: Deploy Backend
echo ""
echo "Step 4: Deploying backend..."
chmod +x deploy-backend.sh
./deploy-backend.sh

# Step 5: Deploy Frontend
echo ""
echo "Step 5: Deploying frontend..."
chmod +x deploy-frontend.sh
./deploy-frontend.sh

echo ""
echo "🎉 Deployment Complete!"
echo "======================="

if [ -f "./backend-url.env" ]; then
    source ./backend-url.env
    echo "🔗 Backend URL: $BACKEND_URL"
fi

FRONTEND_URL=$(gcloud run services describe genai-frontend \
    --platform=managed \
    --region=us-central1 \
    --format="value(status.url)" \
    --project=sdlc-468305 2>/dev/null || echo "Not deployed")

echo "🌐 Frontend URL: $FRONTEND_URL"
echo ""
echo "📋 Next Steps:"
echo "1. Visit your application at the Frontend URL"
echo "2. Set up your Google AI Studio API key in the backend environment"
echo "3. Test the story generation functionality"
echo "4. Monitor the application using Cloud Run logs"
