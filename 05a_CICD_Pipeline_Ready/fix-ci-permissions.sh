#!/bin/bash

# Fix CI/CD Permissions for StoryGen
set -e

PROJECT_ID="sdlc-468305"
SERVICE_ACCOUNT="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🔧 Fixing CI/CD permissions for StoryGen..."
echo "Project ID: $PROJECT_ID"
echo "Service Account: $SERVICE_ACCOUNT"
echo ""

# Check if service account exists
if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" --project="$PROJECT_ID" &>/dev/null; then
    echo "❌ Service account $SERVICE_ACCOUNT does not exist"
    echo "Please run the Workload Identity setup from FORK_SETUP.md first"
    exit 1
fi

echo "✅ Service account exists"

# Add necessary permissions for Artifact Registry
echo "🔧 Adding Artifact Registry permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/artifactregistry.writer" || echo "Role already exists"

# Add Cloud Build permissions  
echo "🔧 Adding Cloud Build permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/cloudbuild.builds.builder" || echo "Role already exists"

# Add Storage permissions for build cache
echo "🔧 Adding Storage permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.admin" || echo "Role already exists"

# Add Service Usage permissions
echo "🔧 Adding Service Usage permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/serviceusage.serviceUsageAdmin" || echo "Role already exists"

echo ""
echo "✅ Permissions updated!"
echo ""
echo "Now you can try pushing to main branch again."
echo "The CI/CD pipeline should have the necessary permissions to:"
echo "- Push to Artifact Registry repositories"
echo "- Deploy to Cloud Run"
echo "- Enable required APIs"
echo ""
echo "If you still get permission errors, check the GitHub Actions logs"
echo "and ensure your Workload Identity Provider is set up correctly."
