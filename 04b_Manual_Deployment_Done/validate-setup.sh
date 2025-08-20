#!/bin/bash

echo "🔍 StoryGen Deployment Validation"
echo "================================="

# Check if .env file exists
if [ -f "../.env" ]; then
    echo "✅ Environment file found"
    source ./load-env.sh
else
    echo "❌ Environment file not found: ../.env"
    echo "   Please create a .env file from env.template"
    exit 1
fi

# Check required tools
echo ""
echo "🔧 Checking required tools..."

if command -v gcloud &> /dev/null; then
    echo "✅ gcloud CLI found"
    GCLOUD_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ "$GCLOUD_PROJECT" = "$PROJECT_ID" ]; then
        echo "✅ gcloud project matches .env configuration: $PROJECT_ID"
    else
        echo "⚠️  gcloud project ($GCLOUD_PROJECT) differs from .env ($PROJECT_ID)"
        echo "   Run: gcloud config set project $PROJECT_ID"
    fi
else
    echo "❌ gcloud CLI not found"
fi

if command -v terraform &> /dev/null; then
    echo "✅ terraform found"
else
    echo "❌ terraform not found"
fi

if command -v docker &> /dev/null; then
    echo "✅ docker found"
else
    echo "❌ docker not found (Cloud Build will be used instead)"
fi

# Check authentication
echo ""
echo "🔐 Checking authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &>/dev/null; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
    echo "✅ Authenticated as: $ACTIVE_ACCOUNT"
else
    echo "❌ No active gcloud authentication"
    echo "   Run: gcloud auth login && gcloud auth application-default login"
fi

# Check required variables
echo ""
echo "📋 Checking required environment variables..."
required_vars=(
    "GOOGLE_CLOUD_PROJECT_ID"
    "GOOGLE_API_KEY"
    "GENMEDIA_BUCKET"
    "SECRET_MANAGER"
)

for var in "${required_vars[@]}"; do
    if [ -n "${!var}" ]; then
        echo "✅ $var is set"
    else
        echo "❌ $var is not set"
    fi
done

echo ""
echo "🎯 Configuration Summary:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Backend Service: $BACKEND_SERVICE_NAME"
echo "   Frontend Service: $FRONTEND_SERVICE_NAME"
echo "   Bucket: $BUCKET_NAME"
echo "   Secret: $SECRET_NAME"
echo "   Artifact Repo: $ARTIFACT_REPO"

echo ""
echo "🚀 Ready to deploy? Run: ./deploy-complete-new.sh"
