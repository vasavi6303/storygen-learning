#!/bin/bash

# 🔍 StoryGen Workload Identity Validation Script
# This script validates that Workload Identity is configured correctly
# and that the CI/CD pipeline should work.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 StoryGen Workload Identity Validation${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}📋 Checking Prerequisites${NC}"
echo "=========================="

if ! command_exists gcloud; then
    echo -e "${RED}❌ gcloud CLI not found${NC}"
    echo "Please install the Google Cloud CLI first"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI found${NC}"

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
    echo -e "${RED}❌ Not authenticated with gcloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
echo -e "${GREEN}✅ Authenticated as: ${CURRENT_ACCOUNT}${NC}"

# Get project ID
if [ -n "$PROJECT_ID" ]; then
    echo "Using PROJECT_ID from environment: $PROJECT_ID"
else
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        PROJECT_ID="$CURRENT_PROJECT"
        echo "Using current project: $PROJECT_ID"
    else
        read -p "Google Cloud Project ID: " PROJECT_ID
    fi
fi

echo ""
echo -e "${BLUE}🔍 Validating Workload Identity Configuration${NC}"
echo "=============================================="

# Default values for validation
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
SERVICE_ACCOUNT_NAME="github-actions"

# Check project access
echo "🔍 Checking project access..."
if gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Project '$PROJECT_ID' is accessible${NC}"
else
    echo -e "${RED}❌ Project '$PROJECT_ID' not accessible${NC}"
    exit 1
fi

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null || echo "unknown")
echo -e "${GREEN}✅ Project number: $PROJECT_NUMBER${NC}"

# Check required APIs
echo ""
echo "🔧 Checking required APIs..."
REQUIRED_APIS=(
    "iamcredentials.googleapis.com"
    "iam.googleapis.com"
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "artifactregistry.googleapis.com"
    "secretmanager.googleapis.com"
)

ALL_APIS_ENABLED=true
for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:$api" --format="value(name)" --project="$PROJECT_ID" | grep -q "$api"; then
        echo -e "  ${GREEN}✅ $api enabled${NC}"
    else
        echo -e "  ${RED}❌ $api not enabled${NC}"
        ALL_APIS_ENABLED=false
    fi
done

if [ "$ALL_APIS_ENABLED" = true ]; then
    echo -e "${GREEN}✅ All required APIs are enabled${NC}"
else
    echo -e "${YELLOW}⚠️ Some APIs are not enabled. Run the setup script to enable them.${NC}"
fi

# Check Workload Identity Pool
echo ""
echo "🔍 Checking Workload Identity Pool..."
if gcloud iam workload-identity-pools describe "$POOL_NAME" \
   --project="$PROJECT_ID" --location="global" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Workload Identity Pool '$POOL_NAME' exists${NC}"
else
    echo -e "${RED}❌ Workload Identity Pool '$POOL_NAME' not found${NC}"
    echo "   Run the setup script to create it: ./setup-workload-identity.sh"
    exit 1
fi

# Check Workload Identity Provider
echo ""
echo "🔍 Checking Workload Identity Provider..."
if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
   --project="$PROJECT_ID" --location="global" \
   --workload-identity-pool="$POOL_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Workload Identity Provider '$PROVIDER_NAME' exists${NC}"
else
    echo -e "${RED}❌ Workload Identity Provider '$PROVIDER_NAME' not found${NC}"
    echo "   Run the setup script to create it: ./setup-workload-identity.sh"
    exit 1
fi

# Check service account
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
echo "🔍 Checking service account..."
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" \
   --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Service account '$SERVICE_ACCOUNT_EMAIL' exists${NC}"
else
    echo -e "${RED}❌ Service account '$SERVICE_ACCOUNT_EMAIL' not found${NC}"
    echo "   Run the setup script to create it: ./setup-workload-identity.sh"
    exit 1
fi

# Check service account permissions
echo ""
echo "🔐 Checking service account permissions..."
REQUIRED_ROLES=(
    "roles/run.admin"
    "roles/storage.admin"
    "roles/artifactregistry.admin"
    "roles/secretmanager.admin"
    "roles/cloudbuild.builds.editor"
    "roles/editor"
)

ALL_ROLES_ASSIGNED=true
for role in "${REQUIRED_ROLES[@]}"; do
    if gcloud projects get-iam-policy "$PROJECT_ID" \
       --flatten="bindings[].members" \
       --filter="bindings.role:$role AND bindings.members:serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
       --format="value(bindings.role)" | grep -q "$role"; then
        echo -e "  ${GREEN}✅ $role assigned${NC}"
    else
        echo -e "  ${RED}❌ $role not assigned${NC}"
        ALL_ROLES_ASSIGNED=false
    fi
done

if [ "$ALL_ROLES_ASSIGNED" = true ]; then
    echo -e "${GREEN}✅ All required roles are assigned${NC}"
else
    echo -e "${YELLOW}⚠️ Some roles are missing. Run the setup script to assign them.${NC}"
fi

# Generate GitHub configuration values
echo ""
echo -e "${CYAN}📋 GitHub Repository Configuration Values${NC}"
echo "=========================================="

WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"

echo ""
echo -e "${YELLOW}🔑 GitHub Repository Secrets:${NC}"
echo "Add these to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions"
echo ""
echo -e "${BLUE}WORKLOAD_IDENTITY_PROVIDER:${NC}"
echo "$WORKLOAD_IDENTITY_PROVIDER"
echo ""
echo -e "${BLUE}GCP_SERVICE_ACCOUNT_EMAIL:${NC}"
echo "$SERVICE_ACCOUNT_EMAIL"
echo ""
echo -e "${BLUE}GOOGLE_API_KEY:${NC}"
echo "(Get from https://aistudio.google.com/)"
echo ""

echo -e "${YELLOW}📊 GitHub Repository Variables:${NC}"
echo "Add these to: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/variables/actions"
echo ""
echo -e "${BLUE}GCP_PROJECT_ID:${NC} $PROJECT_ID"
echo -e "${BLUE}GCP_REGION:${NC} us-central1"
echo -e "${BLUE}ARTIFACT_REPO:${NC} storygen-repo"
echo -e "${BLUE}BACKEND_SERVICE_NAME:${NC} genai-backend"
echo -e "${BLUE}FRONTEND_SERVICE_NAME:${NC} genai-frontend"

# Test Workload Identity (if GitHub repository is provided)
echo ""
read -p "GitHub Username (for testing, optional): " GITHUB_USERNAME
if [ -n "$GITHUB_USERNAME" ]; then
    read -p "Repository Name [storygen-main]: " REPO_NAME
    REPO_NAME=${REPO_NAME:-storygen-main}
    
    echo ""
    echo "🔍 Testing Workload Identity binding for $GITHUB_USERNAME/$REPO_NAME..."
    
    # Check if the service account has workload identity user binding for this repo
    PRINCIPAL="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_USERNAME/$REPO_NAME"
    
    if gcloud iam service-accounts get-iam-policy "$SERVICE_ACCOUNT_EMAIL" \
       --project="$PROJECT_ID" \
       --flatten="bindings[].members" \
       --filter="bindings.role:roles/iam.workloadIdentityUser AND bindings.members:$PRINCIPAL" \
       --format="value(bindings.role)" | grep -q "roles/iam.workloadIdentityUser"; then
        echo -e "${GREEN}✅ Workload Identity binding configured for $GITHUB_USERNAME/$REPO_NAME${NC}"
    else
        echo -e "${RED}❌ Workload Identity binding not found for $GITHUB_USERNAME/$REPO_NAME${NC}"
        echo "   Run: gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL \\"
        echo "        --project=\"$PROJECT_ID\" \\"
        echo "        --role=\"roles/iam.workloadIdentityUser\" \\"
        echo "        --member=\"$PRINCIPAL\""
    fi
fi

# Final validation summary
echo ""
echo -e "${CYAN}📋 Validation Summary${NC}"
echo "===================="

if [ "$ALL_APIS_ENABLED" = true ] && [ "$ALL_ROLES_ASSIGNED" = true ]; then
    echo -e "${GREEN}🎉 Workload Identity is configured correctly!${NC}"
    echo ""
    echo -e "${GREEN}✅ Your CI/CD pipeline should work now${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Add the GitHub secrets and variables shown above"
    echo "2. Get your Google AI Studio API key and add it as GOOGLE_API_KEY"
    echo "3. Push to main branch or trigger the workflow manually"
else
    echo -e "${YELLOW}⚠️ Configuration needs attention${NC}"
    echo ""
    echo "Please run the setup script to fix any issues:"
    echo "./setup-workload-identity.sh"
fi

echo ""
echo -e "${BLUE}📚 Additional Resources:${NC}"
echo "- Setup Guide: FORK_SETUP.md"
echo "- CI/CD Documentation: CI_CD_README.md"
echo "- Google AI Studio: https://aistudio.google.com/"
