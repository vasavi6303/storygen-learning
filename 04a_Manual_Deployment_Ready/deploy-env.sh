#!/bin/bash
# StoryGen Deployment Environment Variables

export PROJECT_ID="sdlc-468305"
export REGION="us-central1"
export ARTIFACT_REPO="storygen-repo"

# Backend Configuration
export BACKEND_SERVICE_NAME="genai-backend"
export BACKEND_IMAGE_NAME="storygen-backend"

# Frontend Configuration  
export FRONTEND_SERVICE_NAME="genai-frontend"
export FRONTEND_IMAGE_NAME="storygen-frontend"

# Storage Configuration
export BUCKET_NAME="genai-story-images"

echo "✅ Environment variables set for StoryGen deployment"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Backend Service: $BACKEND_SERVICE_NAME"
echo "Frontend Service: $FRONTEND_SERVICE_NAME"
