#!/bin/bash
set -e

source ./deploy-env.sh

echo "🏗️ Setting up Artifact Registry..."

# Create repository if it doesn't exist
gcloud artifacts repositories create $ARTIFACT_REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository for StoryGen application" \
    --project=$PROJECT_ID || echo "Repository already exists"

# Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev

echo "✅ Artifact Registry setup complete"
