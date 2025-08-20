#!/bin/bash
set -e

echo "🔧 StoryGen Setup - Prerequisites"
echo "================================"

# Load environment variables
source ./load-env.sh

echo ""
echo "🔍 Checking prerequisites..."

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
echo "🔐 Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &>/dev/null; then
    echo "❌ No active gcloud authentication found."
    echo "Please run: gcloud auth login && gcloud auth application-default login"
    exit 1
fi

# Set project
echo "⚙️ Setting up project configuration..."
gcloud config set project "$PROJECT_ID"

# Enable required APIs
echo "🔌 Enabling required APIs..."
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    aiplatform.googleapis.com \
    storage.googleapis.com \
    secretmanager.googleapis.com \
    --project="$PROJECT_ID"

# Create Artifact Registry repository
echo "🏗️ Setting up Artifact Registry..."
gcloud artifacts repositories create "$ARTIFACT_REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Docker repository for StoryGen application" \
    --project="$PROJECT_ID" || echo "Repository already exists"

# Configure Docker authentication
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

# Create Secret Manager secret for API key
echo "🔐 Setting up Secret Manager..."
if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
    echo "✨ Creating secret '$SECRET_NAME'..."
    gcloud secrets create "$SECRET_NAME" \
        --replication-policy="automatic" \
        --project="$PROJECT_ID"
    
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "🔑 Using API key from .env file..."
        echo "📦 Adding API key to secret..."
        echo -n "$GOOGLE_API_KEY" | gcloud secrets versions add "$SECRET_NAME" --data-file=- --project="$PROJECT_ID"
        echo "✅ API key added to Secret Manager successfully"
    else
        echo "❌ GOOGLE_API_KEY not found in .env file"
        exit 1
    fi
else
    echo "✅ Secret '$SECRET_NAME' already exists."
    
    # Update secret with current API key from .env
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "🔄 Updating secret with API key from .env file..."
        echo -n "$GOOGLE_API_KEY" | gcloud secrets versions add "$SECRET_NAME" --data-file=- --project="$PROJECT_ID"
        echo "✅ Secret updated with latest API key"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo "📋 Configuration Summary:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Artifact Repo: $ARTIFACT_REPO"
echo "   Secret: $SECRET_NAME"
echo ""
echo "🎯 Next step: Run ./02-build-images.sh"
