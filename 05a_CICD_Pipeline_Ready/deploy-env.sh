#!/bin/bash
# StoryGen Deployment Environment Variables

# Load configuration from config.env if it exists
if [ -f "config.env" ]; then
    echo "📋 Loading configuration from config.env..."
    source config.env
elif [ -f "config.example.env" ]; then
    echo "⚠️ No config.env found, using config.example.env..."
    echo "⚠️ Please copy config.example.env to config.env and customize it"
    source config.example.env
else
    echo "❌ No configuration file found!"
    echo "Please create config.env from config.example.env"
    exit 1
fi

# Validate required variables
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-project-id" ]; then
    echo "❌ PROJECT_ID not set or using placeholder value"
    echo "Please set PROJECT_ID in config.env"
    exit 1
fi

# Set defaults for optional variables
export PROJECT_ID="${PROJECT_ID}"
export REGION="${REGION:-us-central1}"
export ARTIFACT_REPO="${ARTIFACT_REPO:-storygen-repo}"
export BACKEND_SERVICE_NAME="${BACKEND_SERVICE_NAME:-genai-backend}"
export BACKEND_IMAGE_NAME="${BACKEND_IMAGE_NAME:-storygen-backend}"
export FRONTEND_SERVICE_NAME="${FRONTEND_SERVICE_NAME:-genai-frontend}"
export FRONTEND_IMAGE_NAME="${FRONTEND_IMAGE_NAME:-storygen-frontend}"
export BUCKET_NAME="${BUCKET_NAME:-${PROJECT_ID}-story-images}"
export SECRET_NAME="${SECRET_NAME:-storygen-google-api-key}"
export BACKEND_MEMORY="${BACKEND_MEMORY:-2Gi}"
export BACKEND_CPU="${BACKEND_CPU:-2}"
export FRONTEND_MEMORY="${FRONTEND_MEMORY:-1Gi}"
export FRONTEND_CPU="${FRONTEND_CPU:-1}"
export MIN_INSTANCES="${MIN_INSTANCES:-0}"
export MAX_INSTANCES="${MAX_INSTANCES:-2}"

echo "✅ Environment variables set for StoryGen deployment"
echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Backend Service: $BACKEND_SERVICE_NAME"
echo "  Frontend Service: $FRONTEND_SERVICE_NAME"
echo "  Artifact Repository: $ARTIFACT_REPO"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Secret Name: $SECRET_NAME"
