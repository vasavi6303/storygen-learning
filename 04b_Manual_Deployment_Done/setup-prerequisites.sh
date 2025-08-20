#!/bin/bash
set -e

# Load environment variables
source ./load-env.sh

echo "🔧 Setting up deployment prerequisites..."

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
        echo "🔑 Please provide your Google AI Studio API key."
        echo "   Go to https://aistudio.google.com/ to get your key."
        read -sp "Enter API Key: " API_KEY
        echo ""
        
        if [ -z "$API_KEY" ]; then
            echo "❌ No API key provided. You can add it later using:"
            echo "   echo 'YOUR_API_KEY' | gcloud secrets versions add $SECRET_NAME --data-file=- --project=$PROJECT_ID"
        else
            echo "📦 Adding API key to secret..."
            echo -n "$API_KEY" | gcloud secrets versions add "$SECRET_NAME" --data-file=- --project="$PROJECT_ID"
        fi
    fi
else
    echo "✅ Secret '$SECRET_NAME' already exists."
    
    # Check if we should update the secret with the current API key from .env
    if [ -n "$GOOGLE_API_KEY" ]; then
        echo "🔄 Updating secret with API key from .env file..."
        echo -n "$GOOGLE_API_KEY" | gcloud secrets versions add "$SECRET_NAME" --data-file=- --project="$PROJECT_ID"
        echo "✅ Secret updated with latest API key"
    fi
fi

echo "✅ Prerequisites setup complete"
