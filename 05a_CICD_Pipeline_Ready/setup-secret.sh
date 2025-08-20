#!/bin/bash
set -e

# Load environment variables from deploy-env.sh
if [ -f "./deploy-env.sh" ]; then
    source ./deploy-env.sh
else
    echo "❌ deploy-env.sh not found. Please ensure it exists in the current directory."
    exit 1
fi

SECRET_NAME="storygen-google-api-key"

echo "🔐 Setting up Google Cloud Secret Manager..."

# 1. Enable the Secret Manager API
echo "🔧 Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project="$PROJECT_ID"

# 2. Create the secret if it doesn't exist
if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
    echo "✨ Creating secret '$SECRET_NAME'..."
    gcloud secrets create "$SECRET_NAME" \
        --replication-policy="automatic" \
        --project="$PROJECT_ID"
else
    echo "✅ Secret '$SECRET_NAME' already exists."
fi

# 3. Prompt for the API key and add it as a new secret version
echo ""
echo "🔑 Please provide your Google AI Studio API key."
echo "   Go to https://aistudio.google.com/ to get your key."
read -sp "Enter API Key: " API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo "❌ No API key provided. Aborting."
    exit 1
fi

echo "📦 Adding new version for secret '$SECRET_NAME'..."
echo -n "$API_KEY" | gcloud secrets versions add "$SECRET_NAME" --data-file=- --project="$PROJECT_ID"

echo ""
echo "🎉 Secret setup complete!"
echo "   The backend service will now be able to securely access this key during deployment."
