#!/bin/bash

# StoryGen CI/CD Setup Validation Script
# Run this locally to verify your setup before pushing to GitHub

set -e

echo "🔍 StoryGen CI/CD Setup Validation"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_gcloud() {
    if command -v gcloud &> /dev/null; then
        echo -e "✅ ${GREEN}gcloud CLI installed${NC}"
        
        # Check authentication
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
            ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
            echo -e "✅ ${GREEN}Authenticated as: $ACCOUNT${NC}"
        else
            echo -e "❌ ${RED}Not authenticated with gcloud${NC}"
            echo "   Run: gcloud auth login"
            return 1
        fi
    else
        echo -e "❌ ${RED}gcloud CLI not found${NC}"
        echo "   Install from: https://cloud.google.com/sdk/docs/install"
        return 1
    fi
}

check_project() {
    if [ -n "$PROJECT_ID" ]; then
        echo -e "✅ ${GREEN}PROJECT_ID set: $PROJECT_ID${NC}"
        
        # Check if project exists and is accessible
        if gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
            echo -e "✅ ${GREEN}Project accessible${NC}"
        else
            echo -e "❌ ${RED}Project not accessible or doesn't exist${NC}"
            return 1
        fi
    else
        echo -e "❌ ${RED}PROJECT_ID not set${NC}"
        echo "   Export your project ID: export PROJECT_ID=\"your-project-id\""
        return 1
    fi
}

check_apis() {
    echo "🔧 Checking required APIs..."
    
    REQUIRED_APIS=(
        "run.googleapis.com"
        "cloudbuild.googleapis.com"
        "artifactregistry.googleapis.com"
        "aiplatform.googleapis.com"
        "storage.googleapis.com"
        "secretmanager.googleapis.com"
        "iamcredentials.googleapis.com"
    )
    
    for api in "${REQUIRED_APIS[@]}"; do
        if gcloud services list --enabled --filter="name:$api" --format="value(name)" --project="$PROJECT_ID" | grep -q "$api"; then
            echo -e "  ✅ ${GREEN}$api enabled${NC}"
        else
            echo -e "  ⚠️ ${YELLOW}$api not enabled${NC}"
            echo "     Enable with: gcloud services enable $api --project=$PROJECT_ID"
        fi
    done
}

check_workload_identity() {
    echo "🔐 Checking Workload Identity setup..."
    
    # Check if workload identity pool exists
    if gcloud iam workload-identity-pools describe "github-pool" \
       --project="$PROJECT_ID" --location="global" > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}Workload Identity Pool exists${NC}"
    else
        echo -e "❌ ${RED}Workload Identity Pool not found${NC}"
        echo "   Create with setup commands in FORK_SETUP.md"
        return 1
    fi
    
    # Check if provider exists
    if gcloud iam workload-identity-pools providers describe "github-provider" \
       --project="$PROJECT_ID" --location="global" \
       --workload-identity-pool="github-pool" > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}Workload Identity Provider exists${NC}"
    else
        echo -e "❌ ${RED}Workload Identity Provider not found${NC}"
        return 1
    fi
    
    # Check service account
    if gcloud iam service-accounts describe "github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
       --project="$PROJECT_ID" > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}GitHub Actions service account exists${NC}"
    else
        echo -e "❌ ${RED}GitHub Actions service account not found${NC}"
        return 1
    fi
}

check_terraform() {
    if command -v terraform &> /dev/null; then
        echo -e "✅ ${GREEN}Terraform installed${NC}"
        
        # Check terraform files
        if [ -f "terraform_code/main.tf" ]; then
            echo -e "✅ ${GREEN}Terraform configuration found${NC}"
        else
            echo -e "❌ ${RED}Terraform configuration not found${NC}"
            return 1
        fi
    else
        echo -e "⚠️ ${YELLOW}Terraform not found locally${NC}"
        echo "   Install from: https://terraform.io"
        echo "   (CI/CD will install it automatically)"
    fi
}

check_files() {
    echo "📁 Checking required files..."
    
    REQUIRED_FILES=(
        ".github/workflows/ci-cd.yml"
        "backend/Dockerfile"
        "frontend/Dockerfile" 
        "terraform_code/main.tf"
        "FORK_SETUP.md"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  ✅ ${GREEN}$file exists${NC}"
        else
            echo -e "  ❌ ${RED}$file missing${NC}"
        fi
    done
}

get_workload_identity_info() {
    echo ""
    echo "📋 Workload Identity Information"
    echo "================================"
    
    if [ -n "$PROJECT_ID" ]; then
        PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)' 2>/dev/null || echo "unknown")
        
        echo "For GitHub repository secrets:"
        echo ""
        echo "WORKLOAD_IDENTITY_PROVIDER:"
        echo "projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
        echo ""
        echo "GCP_SERVICE_ACCOUNT_EMAIL:"
        echo "github-actions@$PROJECT_ID.iam.gserviceaccount.com"
        echo ""
    fi
}

show_summary() {
    echo ""
    echo "📋 Setup Summary"
    echo "================"
    echo ""
    echo "GitHub Repository Variables to set:"
    echo "  GCP_PROJECT_ID: $PROJECT_ID"
    echo "  GCP_REGION: us-central1 (or your preferred region)"
    echo "  ARTIFACT_REPO: storygen-repo"
    echo "  BACKEND_SERVICE_NAME: genai-backend"
    echo "  FRONTEND_SERVICE_NAME: genai-frontend"
    echo ""
    echo "GitHub Repository Secrets to set:"
    echo "  WORKLOAD_IDENTITY_PROVIDER: (see above)"
    echo "  GCP_SERVICE_ACCOUNT_EMAIL: (see above)"
    echo "  GOOGLE_API_KEY: (from aistudio.google.com)"
    echo ""
    echo "Next steps:"
    echo "1. Set repository variables and secrets in GitHub"
    echo "2. Push to main branch or trigger workflow manually"
    echo "3. Monitor deployment in GitHub Actions"
}

# Main validation
echo "Starting validation..."
echo ""

# Read project ID from environment or prompt
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your Google Cloud Project ID: " PROJECT_ID
    export PROJECT_ID
fi

# Run checks
FAILED=0

check_gcloud || FAILED=1
check_project || FAILED=1
check_apis || FAILED=1
check_workload_identity || FAILED=1
check_terraform || FAILED=1
check_files || FAILED=1

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "🎉 ${GREEN}All checks passed! Your setup looks good.${NC}"
    get_workload_identity_info
    show_summary
else
    echo -e "⚠️ ${YELLOW}Some checks failed. Please review the output above.${NC}"
    echo "   See FORK_SETUP.md for detailed setup instructions."
fi

echo ""
echo "For complete setup instructions, see: FORK_SETUP.md"
echo "For CI/CD documentation, see: CI_CD_README.md"
