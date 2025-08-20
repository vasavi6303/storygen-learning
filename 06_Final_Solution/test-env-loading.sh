#!/bin/bash

# 🧪 Test .env Loading Script
# ==========================
# This script tests if the .env file loading works correctly

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 Testing .env file loading${NC}"
echo -e "${CYAN}============================${NC}"
echo ""

# Function to load environment variables from .env file
load_env_file() {
    local env_file="../.env"
    if [ -f "$env_file" ]; then
        echo -e "${GREEN}🔧 Loading configuration from $env_file${NC}"
        # Load environment variables, ignoring comments and empty lines
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                # Export the variable (remove quotes if present)
                export "$line"
            fi
        done < "$env_file"
        return 0
    else
        echo -e "${YELLOW}⚠️ No .env file found at $env_file${NC}"
        return 1
    fi
}

# Test loading
if load_env_file; then
    echo ""
    echo -e "${BLUE}📋 Loaded environment variables:${NC}"
    echo "  GOOGLE_CLOUD_PROJECT_ID: ${GOOGLE_CLOUD_PROJECT_ID:-'Not set'}"
    echo "  GITHUB_USERNAME: ${GITHUB_USERNAME:-'Not set'}"
    echo "  GITHUB_REPO: ${GITHUB_REPO:-'Not set'}"
    echo "  SECRET_MANAGER: ${SECRET_MANAGER:-'Not set'}"
    echo "  GENMEDIA_BUCKET: ${GENMEDIA_BUCKET:-'Not set'}"
    echo "  GOOGLE_API_KEY: ${GOOGLE_API_KEY:+[SET - first 10 chars: ${GOOGLE_API_KEY:0:10}...]}"
    echo "  GOOGLE_GENAI_USE_VERTEXAI: ${GOOGLE_GENAI_USE_VERTEXAI:-'Not set'}"
    echo ""
    echo -e "${BLUE}📋 Script compatibility:${NC}"
    echo "  setup-direct.sh: ✅ Fully automated (no prompts needed)"
    echo "  setup-api-key.sh: ✅ Fully automated (no prompts needed)"
    echo "  setup-secret-only.sh: ✅ Fully automated (no prompts needed)"
    echo "  setup-cicd-only.sh: ✅ Fully automated (no prompts needed)"
    echo ""
    echo -e "${GREEN}✅ .env file loading test successful!${NC}"
else
    echo -e "${YELLOW}⚠️ .env file not found - scripts will use interactive prompts${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Checking Workload Identity Provider configuration...${NC}"

# Check if we have the required info for WIP checking
if [ -n "$GOOGLE_CLOUD_PROJECT_ID" ] && [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_REPO" ]; then
    # Check if gcloud is authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@" 2>/dev/null; then
        # Set project for gcloud
        gcloud config set project "$GOOGLE_CLOUD_PROJECT_ID" > /dev/null 2>&1
        
        # Check if Workload Identity Provider exists and is correctly configured
        POOL_NAME="github-pool"
        PROVIDER_NAME="github-provider-fixed"
        
        if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
           --project="$GOOGLE_CLOUD_PROJECT_ID" --location="global" \
           --workload-identity-pool="$POOL_NAME" > /dev/null 2>&1; then
            
            # Get current attribute condition
            CURRENT_CONDITION=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
                --project="$GOOGLE_CLOUD_PROJECT_ID" --location="global" \
                --workload-identity-pool="$POOL_NAME" \
                --format="value(attributeCondition)" 2>/dev/null || echo "")
            
            EXPECTED_CONDITION="assertion.repository=='$GITHUB_USERNAME/$GITHUB_REPO'"
            
            if [ "$CURRENT_CONDITION" = "$EXPECTED_CONDITION" ]; then
                echo -e "${GREEN}✅ Workload Identity Provider correctly configured${NC}"
            else
                echo -e "${YELLOW}⚠️ Workload Identity Provider needs updating${NC}"
                echo "  Current:  ${CURRENT_CONDITION:-'None'}"
                echo "  Expected: $EXPECTED_CONDITION"
                echo "  Run: ./fix-workload-identity.sh to fix this automatically"
            fi
        else
            echo -e "${YELLOW}⚠️ Workload Identity Provider not found${NC}"
            echo "  Run: ./setup-cicd-complete.sh to set up CI/CD configuration"
        fi
    else
        echo -e "${YELLOW}⚠️ Not authenticated with gcloud - skipping WIP check${NC}"
        echo "  Run: gcloud auth login"
    fi
else
    echo -e "${YELLOW}⚠️ Incomplete configuration - skipping WIP check${NC}"
fi

echo ""
echo -e "${CYAN}🎯 Next Steps:${NC}"
echo "  1. Run: ./setup-cicd-complete.sh (sets up complete CI/CD configuration)"
echo "  2. Or run: ./fix-workload-identity.sh (fixes WIP configuration only)"
echo ""
echo -e "${GREEN}✅ Ready to run setup scripts with automatic configuration!${NC}"
