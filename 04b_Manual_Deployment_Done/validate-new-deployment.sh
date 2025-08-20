#!/bin/bash

echo "🔍 StoryGen New Deployment Validation"
echo "====================================="

# Check if .env file exists
if [ -f "../.env" ]; then
    echo "✅ Environment file found: ../.env"
    source ./load-env.sh
else
    echo "❌ Environment file not found: ../.env"
    echo "   Please create a .env file from env.template"
    exit 1
fi

echo ""
echo "🔧 Checking deployment scripts..."

# Check script files
scripts=("01-setup.sh" "02-build-images.sh" "03-deploy-infrastructure.sh" "deploy-all.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "✅ $script (executable)"
    elif [ -f "$script" ]; then
        echo "⚠️  $script (not executable) - run: chmod +x $script"
    else
        echo "❌ $script (missing)"
    fi
done

echo ""
echo "🔧 Checking required tools..."

tools=("gcloud" "terraform" "docker")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool found"
    else
        echo "❌ $tool not found"
    fi
done

echo ""
echo "🔐 Checking authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &>/dev/null; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
    echo "✅ Authenticated as: $ACTIVE_ACCOUNT"
    
    # Check project access
    if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
        echo "✅ Project access: $PROJECT_ID"
    else
        echo "❌ Cannot access project: $PROJECT_ID"
    fi
else
    echo "❌ No active gcloud authentication"
fi

echo ""
echo "📋 Checking required environment variables..."
required_vars=(
    "GOOGLE_CLOUD_PROJECT_ID"
    "GOOGLE_API_KEY"
    "GENMEDIA_BUCKET"
    "SECRET_MANAGER"
)

all_vars_set=true
for var in "${required_vars[@]}"; do
    if [ -n "${!var}" ]; then
        echo "✅ $var is set"
    else
        echo "❌ $var is not set"
        all_vars_set=false
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
if [ "$all_vars_set" = true ]; then
    echo "🚀 Ready to deploy!"
    echo ""
    echo "Deployment options:"
    echo "   Full deployment:  ./deploy-all.sh"
    echo "   Step by step:"
    echo "     1. ./01-setup.sh"
    echo "     2. ./02-build-images.sh"
    echo "     3. ./03-deploy-infrastructure.sh"
else
    echo "❌ Please fix the missing environment variables first."
fi

echo ""
echo "📖 For help, see: NEW_DEPLOYMENT_GUIDE.md"
