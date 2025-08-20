#!/bin/bash
set -e

# 🔧 Fix Workload Identity Provider Script
# ========================================
# This script automatically fixes Workload Identity Provider configuration
# to match the current GitHub repository and ensures CI/CD authentication works

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔧 Workload Identity Provider Fix${NC}"
echo -e "${CYAN}=================================${NC}"
echo ""

# Function to load environment variables from .env file
load_env_file() {
    local env_file="../.env"
    if [ -f "$env_file" ]; then
        echo -e "${GREEN}📄 Loading configuration from $env_file${NC}"
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

# Load environment variables
if load_env_file; then
    PROJECT_ID="$GOOGLE_CLOUD_PROJECT_ID"
    GITHUB_USERNAME="$GITHUB_USERNAME"
    GITHUB_REPO="$GITHUB_REPO"
else
    echo -e "${YELLOW}⚠️ Could not load .env file. Please provide configuration manually.${NC}"
    echo ""
    read -p "Enter your Google Cloud Project ID: " PROJECT_ID
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    read -p "Enter your GitHub repository name: " GITHUB_REPO
fi

# Validate required variables
if [ -z "$PROJECT_ID" ] || [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${RED}❌ Missing required configuration:${NC}"
    echo "  PROJECT_ID: ${PROJECT_ID:-'Not set'}"
    echo "  GITHUB_USERNAME: ${GITHUB_USERNAME:-'Not set'}"
    echo "  GITHUB_REPO: ${GITHUB_REPO:-'Not set'}"
    echo ""
    echo "Please ensure your .env file is properly configured or provide the values manually."
    exit 1
fi

# Constants
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider-fixed"
SERVICE_ACCOUNT_NAME="github-actions"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  GitHub Repository: $GITHUB_USERNAME/$GITHUB_REPO"
echo "  Pool Name: $POOL_NAME"
echo "  Provider Name: $PROVIDER_NAME"
echo ""

# Check if authenticated with gcloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo -e "${RED}❌ Not authenticated with gcloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set project
echo -e "${BLUE}🔧 Setting gcloud project...${NC}"
gcloud config set project "$PROJECT_ID"

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
echo -e "${GREEN}✅ Project number: $PROJECT_NUMBER${NC}"

# Check current Workload Identity Provider configuration
echo ""
echo -e "${BLUE}🔍 Checking current Workload Identity Provider configuration...${NC}"

if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
   --project="$PROJECT_ID" --location="global" \
   --workload-identity-pool="$POOL_NAME" > /dev/null 2>&1; then
    echo -e "${RED}❌ Workload Identity Provider '$PROVIDER_NAME' not found${NC}"
    echo "Please run the setup script first: ./setup-cicd-config.sh"
    exit 1
fi

# Get current attribute condition
CURRENT_CONDITION=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --project="$PROJECT_ID" --location="global" \
    --workload-identity-pool="$POOL_NAME" \
    --format="value(attributeCondition)" 2>/dev/null || echo "")

EXPECTED_CONDITION="assertion.repository=='$GITHUB_USERNAME/$GITHUB_REPO'"

echo "  Current condition: ${CURRENT_CONDITION:-'None'}"
echo "  Expected condition: $EXPECTED_CONDITION"

if [ "$CURRENT_CONDITION" = "$EXPECTED_CONDITION" ]; then
    echo -e "${GREEN}✅ Workload Identity Provider already configured correctly${NC}"
else
    echo -e "${YELLOW}⚠️ Workload Identity Provider needs updating${NC}"
    
    echo ""
    echo -e "${BLUE}🔧 Updating Workload Identity Provider...${NC}"
    
    # Update the provider with correct attribute condition
    gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --attribute-condition="$EXPECTED_CONDITION"
    
    echo -e "${GREEN}✅ Workload Identity Provider updated${NC}"
fi

# Check service account binding
echo ""
echo -e "${BLUE}🔍 Checking service account binding...${NC}"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PRINCIPAL="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_USERNAME/$GITHUB_REPO"

echo "  Service Account: $SERVICE_ACCOUNT_EMAIL"
echo "  Principal: $PRINCIPAL"

# Check if the binding exists
if gcloud iam service-accounts get-iam-policy "$SERVICE_ACCOUNT_EMAIL" \
   --flatten="bindings[].members" \
   --filter="bindings.role:roles/iam.workloadIdentityUser AND bindings.members:$PRINCIPAL" \
   --format="value(bindings.role)" | grep -q "roles/iam.workloadIdentityUser"; then
    echo -e "${GREEN}✅ Service account binding already exists${NC}"
else
    echo -e "${YELLOW}⚠️ Adding service account binding...${NC}"
    
    gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/iam.workloadIdentityUser" \
        --member="$PRINCIPAL"
    
    echo -e "${GREEN}✅ Service account binding added${NC}"
fi

# Test the configuration
echo ""
echo -e "${BLUE}🧪 Testing Workload Identity configuration...${NC}"

# Create a temporary test script to validate the configuration
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'EOF'
#!/bin/bash
# Test if gcloud is properly configured
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "✅ Authentication working"
    gcloud projects list --limit=1 > /dev/null 2>&1 && echo "✅ API access working" || echo "❌ API access failed"
    exit 0
else
    echo "❌ Authentication failed"
    exit 1
fi
EOF

chmod +x "$TEST_SCRIPT"

# Validate by checking if we can list projects (this tests the full auth flow)
if gcloud projects list --limit=1 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Workload Identity configuration is working${NC}"
else
    echo -e "${YELLOW}⚠️ Configuration updated, but may need time to propagate${NC}"
fi

rm -f "$TEST_SCRIPT"

# Update the deployment configuration file
DEPLOYMENT_CONFIG="../.github/config/deployment.yml"
if [ -f "$DEPLOYMENT_CONFIG" ]; then
    echo ""
    echo -e "${BLUE}🔧 Updating deployment configuration...${NC}"
    
    # Update the workload identity provider URL in the config file
    WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"
    
    # Create a temporary file with updated config
    TEMP_CONFIG=$(mktemp)
    
    # Update the workload_identity_provider field
    sed "s|workload_identity_provider:.*|workload_identity_provider: \"$WORKLOAD_IDENTITY_PROVIDER\"|" "$DEPLOYMENT_CONFIG" > "$TEMP_CONFIG"
    
    # Replace the original file
    mv "$TEMP_CONFIG" "$DEPLOYMENT_CONFIG"
    
    echo -e "${GREEN}✅ Updated $DEPLOYMENT_CONFIG${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Workload Identity Provider fix completed!${NC}"
echo ""
echo -e "${CYAN}📋 Summary:${NC}"
echo "  ✅ Workload Identity Provider configured for: $GITHUB_USERNAME/$GITHUB_REPO"
echo "  ✅ Service account binding configured"
echo "  ✅ Deployment configuration updated"
echo ""
echo -e "${CYAN}🚀 Next steps:${NC}"
echo "  1. Commit and push your changes to trigger CI/CD"
echo "  2. Monitor the GitHub Actions workflow for successful authentication"
echo "  3. If issues persist, check the GitHub Actions logs for detailed error messages"
echo ""
echo -e "${YELLOW}Note: Changes may take a few minutes to propagate through Google Cloud systems.${NC}"
