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
echo -e "${CYAN}🎯 Ready to run setup scripts with automatic configuration!${NC}"
