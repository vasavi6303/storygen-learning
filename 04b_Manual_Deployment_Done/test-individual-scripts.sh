#!/bin/bash

echo "🧪 Testing Individual Script Workflow"
echo "====================================="

# Load environment
if [ ! -f "../.env" ]; then
    echo "❌ .env file not found. Please create it first."
    exit 1
fi

source ./load-env.sh

echo ""
echo "📋 Test Configuration:"
echo "   Project: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Scripts to test: 01-setup.sh, 02-build-images.sh, 03-deploy-infrastructure.sh"
echo ""

# Check if all scripts exist and are executable
scripts=("01-setup.sh" "02-build-images.sh" "03-deploy-infrastructure.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "✅ $script (ready)"
    else
        echo "❌ $script (missing or not executable)"
        echo "   Run: chmod +x $script"
        exit 1
    fi
done

echo ""
echo "🎯 Individual Script Test Instructions:"
echo "======================================="
echo ""
echo "Run these commands one by one:"
echo ""
echo "1. 📋 Prerequisites Setup:"
echo "   ./01-setup.sh"
echo ""
echo "2. 🔨 Build Docker Images:"
echo "   ./02-build-images.sh"
echo ""
echo "3. 🏗️ Deploy Infrastructure:"
echo "   ./03-deploy-infrastructure.sh"
echo ""
echo "Expected Results:"
echo "- Step 1: APIs enabled, Artifact Registry created, secrets set up"
echo "- Step 2: Docker images built and pushed to Artifact Registry"
echo "- Step 3: Cloud Run services deployed with working URLs"
echo ""
echo "🚀 Ready to test! Run each script individually."
