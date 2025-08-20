#!/bin/bash

# Quick Fix for CI/CD Permissions
set -e

PROJECT_ID="sdlc-468305"
SERVICE_ACCOUNT="cicd-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🔧 Quick fix for CI/CD permissions..."
echo "Project ID: $PROJECT_ID"
echo "Service Account: $SERVICE_ACCOUNT"
echo ""

# Add Artifact Registry write permissions
echo "🔧 Adding Artifact Registry permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/artifactregistry.writer"

# Add Cloud Build permissions  
echo "🔧 Adding Cloud Build permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/cloudbuild.builds.builder"

# Add Storage permissions
echo "🔧 Adding Storage permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.admin"

# Add Cloud Run admin permissions
echo "🔧 Adding Cloud Run permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.admin"

# Add Service Usage permissions
echo "🔧 Adding Service Usage permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/serviceusage.serviceUsageAdmin"

# Add Editor role for comprehensive access
echo "🔧 Adding Editor permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/editor"

echo ""
echo "✅ Permissions updated for cicd-sa!"
echo ""
echo "Now update your CI/CD workflow to use the correct service account."
