#!/bin/bash

# 🔐 StoryGen Workload Identity Setup Script
# This script configures GitHub Actions authentication with Google Cloud Platform
# using Workload Identity Federation for secure, keyless authentication.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
DEFAULT_REGION="us-central1"
DEFAULT_POOL_NAME="github-pool"
DEFAULT_PROVIDER_NAME="github-provider"
DEFAULT_SERVICE_ACCOUNT="github-actions"
DEFAULT_BUCKET_SUFFIX="story-images"

echo -e "${CYAN}🔐 StoryGen Workload Identity Setup${NC}"
echo -e "${CYAN}===================================${NC}"
echo ""
echo "This script will configure GitHub Actions authentication with Google Cloud"
echo "using Workload Identity Federation. This is required for the CI/CD pipeline."
echo ""

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    read -p "$prompt [$default]: " input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}📋 Checking Prerequisites${NC}"
echo "=========================="

if ! command_exists gcloud; then
    echo -e "${RED}❌ gcloud CLI not found${NC}"
    echo "Please install the Google Cloud CLI first:"
    echo "https://cloud.google.com/sdk/docs/install"
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
echo ""

# Get configuration
echo -e "${BLUE}📝 Configuration${NC}"
echo "================"

# Project ID
if [ -n "$PROJECT_ID" ]; then
    echo "Using PROJECT_ID from environment: $PROJECT_ID"
else
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        prompt_with_default "Google Cloud Project ID" "$CURRENT_PROJECT" "PROJECT_ID"
    else
        read -p "Google Cloud Project ID: " PROJECT_ID
    fi
fi

# Validate project exists and is accessible
echo "🔍 Validating project access..."
if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${RED}❌ Project '$PROJECT_ID' not accessible or doesn't exist${NC}"
    echo "Please check the project ID and ensure you have access."
    exit 1
fi
echo -e "${GREEN}✅ Project '$PROJECT_ID' is accessible${NC}"

# Region
prompt_with_default "Deployment Region" "$DEFAULT_REGION" "REGION"

# GitHub repository information
echo ""
echo "🐙 GitHub Repository Information"
echo "================================"
read -p "GitHub Username: " GITHUB_USERNAME
read -p "Repository Name [storygen-main]: " REPO_NAME
REPO_NAME=${REPO_NAME:-storygen-main}

# Service account name (will be created)
echo ""
echo -e "${YELLOW}📝 Service Account Configuration${NC}"
echo "The script will CREATE a new service account for GitHub Actions."
echo "You can use the default name or choose your own."
prompt_with_default "Service Account Name (will be created)" "$DEFAULT_SERVICE_ACCOUNT" "SERVICE_ACCOUNT_NAME"

# Workload Identity Pool and Provider names
prompt_with_default "Workload Identity Pool Name" "$DEFAULT_POOL_NAME" "POOL_NAME"
prompt_with_default "Workload Identity Provider Name" "$DEFAULT_PROVIDER_NAME" "PROVIDER_NAME"

echo ""
echo -e "${BLUE}📋 Configuration Summary${NC}"
echo "========================"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  GitHub Repo: $GITHUB_USERNAME/$REPO_NAME"
echo "  Service Account: $SERVICE_ACCOUNT_NAME"
echo "  Identity Pool: $POOL_NAME"
echo "  Identity Provider: $PROVIDER_NAME"
echo ""

read -p "Is this configuration correct? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled. Please run the script again."
    exit 1
fi

echo ""
echo -e "${CYAN}🚀 Starting Workload Identity Setup${NC}"
echo "===================================="

# Set the project
echo "🔧 Setting gcloud project..."
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✅ Project set to $PROJECT_ID${NC}"

# Enable required APIs
echo ""
echo "🔧 Enabling required Google Cloud APIs..."
echo "This may take a few minutes for all services to be enabled..."

# Enable APIs in batches to avoid rate limiting
echo "  📡 Enabling core IAM and resource management APIs..."
gcloud services enable \
    iamcredentials.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    serviceusage.googleapis.com \
    --project="$PROJECT_ID"

echo "  📦 Enabling deployment and container APIs..."
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    --project="$PROJECT_ID"

echo "  🤖 Enabling AI and ML APIs..."
gcloud services enable \
    aiplatform.googleapis.com \
    generativelanguage.googleapis.com \
    --project="$PROJECT_ID"

echo "  🔐 Enabling storage and security APIs..."
gcloud services enable \
    storage.googleapis.com \
    secretmanager.googleapis.com \
    --project="$PROJECT_ID"

echo -e "${GREEN}✅ All required APIs enabled${NC}"

# Get project number
echo ""
echo "🔍 Getting project number..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
echo -e "${GREEN}✅ Project number: $PROJECT_NUMBER${NC}"

# Create Workload Identity Pool
echo ""
echo "🏗️ Creating Workload Identity Pool: $POOL_NAME"
echo "This allows GitHub Actions to authenticate with Google Cloud..."

if gcloud iam workload-identity-pools describe "$POOL_NAME" \
   --project="$PROJECT_ID" --location="global" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Workload Identity Pool '$POOL_NAME' already exists${NC}"
else
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --display-name="GitHub Actions Pool for $REPO_NAME"
    echo -e "${GREEN}✅ Workload Identity Pool created${NC}"
fi

# Create Workload Identity Provider
echo ""
echo "🏗️ Creating Workload Identity Provider: $PROVIDER_NAME"
echo "This configures how GitHub tokens are mapped to Google Cloud identities..."

if gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
   --project="$PROJECT_ID" --location="global" \
   --workload-identity-pool="$POOL_NAME" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Workload Identity Provider '$PROVIDER_NAME' already exists${NC}"
else
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --display-name="GitHub Actions Provider for $REPO_NAME" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
        --issuer-uri="https://token.actions.githubusercontent.com"
    echo -e "${GREEN}✅ Workload Identity Provider created${NC}"
fi

# Create service account
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "🏗️ Creating service account: $SERVICE_ACCOUNT_EMAIL"
echo "This account will be used by GitHub Actions to access Google Cloud resources..."

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" \
   --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Service account '$SERVICE_ACCOUNT_EMAIL' already exists${NC}"
else
    gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --project="$PROJECT_ID" \
        --display-name="GitHub Actions Service Account for $REPO_NAME"
    echo -e "${GREEN}✅ Service account created${NC}"
fi

# Grant IAM roles to service account
echo ""
echo "🔐 Granting IAM roles to service account..."
echo "These permissions allow the service account to deploy and manage resources..."

# Core deployment roles
echo "  🚀 Granting deployment permissions..."
DEPLOYMENT_ROLES=(
    "roles/run.admin"
    "roles/cloudbuild.builds.editor"
    "roles/artifactregistry.admin"
    "roles/serviceusage.serviceUsageAdmin"
)

for role in "${DEPLOYMENT_ROLES[@]}"; do
    echo "    🔧 Granting $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" > /dev/null
done

# Storage and security roles
echo "  🔐 Granting storage and security permissions..."
STORAGE_SECURITY_ROLES=(
    "roles/storage.admin"
    "roles/secretmanager.admin"
)

for role in "${STORAGE_SECURITY_ROLES[@]}"; do
    echo "    🔧 Granting $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" > /dev/null
done

# AI and ML roles for Vertex AI and Gemini
echo "  🤖 Granting AI/ML permissions for Vertex AI and Gemini..."
AI_ROLES=(
    "roles/aiplatform.admin"
    "roles/aiplatform.user"
    "roles/ml.admin"
    "roles/generativelanguage.viewer"
)

for role in "${AI_ROLES[@]}"; do
    echo "    🔧 Granting $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" > /dev/null
done

# General project permissions
echo "  ⚙️ Granting general project permissions..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/editor" > /dev/null

echo -e "${GREEN}✅ All IAM roles granted${NC}"

# Allow GitHub to impersonate the service account
echo ""
echo "🔗 Configuring GitHub repository access..."
echo "This allows your GitHub repository to impersonate the service account..."

PRINCIPAL="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_USERNAME/$REPO_NAME"

gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="$PRINCIPAL"

echo -e "${GREEN}✅ GitHub repository access configured${NC}"

# Create Cloud Storage bucket for image generation
echo ""
echo "🪣 Setting up Cloud Storage bucket for image generation..."
BUCKET_NAME="${PROJECT_ID}-${DEFAULT_BUCKET_SUFFIX}"

if gsutil ls -b gs://"$BUCKET_NAME" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Bucket '$BUCKET_NAME' already exists${NC}"
else
    echo "Creating bucket: $BUCKET_NAME"
    gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" gs://"$BUCKET_NAME"
    
    # Set bucket permissions for the service account
    gsutil iam ch serviceAccount:"$SERVICE_ACCOUNT_EMAIL":objectAdmin gs://"$BUCKET_NAME"
    
    echo -e "${GREEN}✅ Bucket created and permissions configured${NC}"
fi

# Setup Secret Manager for API keys
echo ""
echo "🔐 Setting up Secret Manager..."
SECRET_NAME="storygen-google-api-key"

# Check if secret exists
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Secret '$SECRET_NAME' already exists${NC}"
    echo "You can update it later with your Gemini API key"
else
    echo "Creating secret: $SECRET_NAME"
    gcloud secrets create "$SECRET_NAME" \
        --replication-policy="automatic" \
        --project="$PROJECT_ID"
    
    echo -e "${GREEN}✅ Secret created${NC}"
    echo -e "${YELLOW}📝 Remember to add your Gemini API key to this secret after setup${NC}"
fi

# Grant service account access to the secret
echo "🔐 Granting service account access to secrets..."
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/secretmanager.secretAccessor" \
    --project="$PROJECT_ID" > /dev/null

echo -e "${GREEN}✅ Secret access configured${NC}"

# Generate the required values for GitHub secrets
echo ""
echo -e "${CYAN}📋 GitHub Repository Configuration${NC}"
echo "=================================="

WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"

echo ""
echo -e "${YELLOW}🔑 Required GitHub Repository Secrets:${NC}"
echo "Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions"
echo ""
echo -e "${BLUE}Secret Name: WORKLOAD_IDENTITY_PROVIDER${NC}"
echo "$WORKLOAD_IDENTITY_PROVIDER"
echo ""
echo -e "${BLUE}Secret Name: GCP_SERVICE_ACCOUNT_EMAIL${NC}"
echo "$SERVICE_ACCOUNT_EMAIL"
echo ""
echo -e "${BLUE}Secret Name: GOOGLE_API_KEY${NC}"
echo "Get your API key from: https://aistudio.google.com/"
echo ""

echo -e "${YELLOW}📊 Required GitHub Repository Variables:${NC}"
echo "Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/variables/actions"
echo ""
echo -e "${BLUE}Variable Name: GCP_PROJECT_ID${NC}"
echo "$PROJECT_ID"
echo ""
echo -e "${BLUE}Variable Name: GCP_REGION${NC}"
echo "$REGION"
echo ""
echo -e "${BLUE}Variable Name: ARTIFACT_REPO${NC}"
echo "storygen-repo"
echo ""
echo -e "${BLUE}Variable Name: BACKEND_SERVICE_NAME${NC}"
echo "genai-backend"
echo ""
echo -e "${BLUE}Variable Name: FRONTEND_SERVICE_NAME${NC}"
echo "genai-frontend"
echo ""
echo -e "${BLUE}Variable Name: BUCKET_NAME${NC}"
echo "$BUCKET_NAME"
echo ""
echo -e "${BLUE}Variable Name: SECRET_NAME${NC}"
echo "$SECRET_NAME"
echo ""

# Create a summary file
SUMMARY_FILE="workload-identity-setup-summary.txt"
echo "📝 Creating setup summary file: $SUMMARY_FILE"

cat > "$SUMMARY_FILE" << EOF
# 🔐 StoryGen Workload Identity Setup Summary
# Generated on $(date)

## Configuration Used
Project ID: $PROJECT_ID
Region: $REGION
GitHub Repository: $GITHUB_USERNAME/$REPO_NAME
Service Account: $SERVICE_ACCOUNT_EMAIL
Workload Identity Pool: $POOL_NAME
Workload Identity Provider: $PROVIDER_NAME
Storage Bucket: $BUCKET_NAME
Secret Name: $SECRET_NAME

## GitHub Repository Secrets (Required)
Add these secrets at: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions

WORKLOAD_IDENTITY_PROVIDER:
$WORKLOAD_IDENTITY_PROVIDER

GCP_SERVICE_ACCOUNT_EMAIL:
$SERVICE_ACCOUNT_EMAIL

GOOGLE_API_KEY:
(Get from https://aistudio.google.com/)

## GitHub Repository Variables (Required)
Add these variables at: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/variables/actions

GCP_PROJECT_ID: $PROJECT_ID
GCP_REGION: $REGION
ARTIFACT_REPO: storygen-repo
BACKEND_SERVICE_NAME: genai-backend
FRONTEND_SERVICE_NAME: genai-frontend
BUCKET_NAME: $BUCKET_NAME
SECRET_NAME: $SECRET_NAME

## Next Steps
1. Add the above secrets and variables to your GitHub repository
2. Get your Gemini API key from https://aistudio.google.com/
3. Add your API key to Secret Manager:
   gcloud secrets versions add $SECRET_NAME --data-file=- --project=$PROJECT_ID
   (Then paste your API key and press Ctrl+D)
4. Add the same API key as GOOGLE_API_KEY secret in GitHub
5. Push to main branch or trigger the CI/CD workflow manually
6. Monitor the deployment in GitHub Actions

## Resources Created
- ✅ Workload Identity Pool and Provider
- ✅ Service Account with comprehensive permissions
- ✅ Cloud Storage bucket: $BUCKET_NAME
- ✅ Secret Manager secret: $SECRET_NAME
- ✅ All required API enablements
- ✅ IAM bindings for GitHub Actions

## Verification Commands
# Test authentication locally
gcloud auth list

# Check Workload Identity Pool
gcloud iam workload-identity-pools describe $POOL_NAME --project=$PROJECT_ID --location=global

# Check service account
gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --project=$PROJECT_ID

## Troubleshooting
If CI/CD still fails:
1. Verify all secrets and variables are set correctly in GitHub
2. Check that the repository name matches exactly: $GITHUB_USERNAME/$REPO_NAME
3. Ensure billing is enabled for project: $PROJECT_ID
4. Check GitHub Actions logs for specific error messages
EOF

echo -e "${GREEN}✅ Summary file created: $SUMMARY_FILE${NC}"

echo ""
echo -e "${CYAN}🎉 Complete StoryGen Setup Finished!${NC}"
echo "===================================="
echo ""
echo -e "${GREEN}✅ Workload Identity Pool and Provider created${NC}"
echo -e "${GREEN}✅ Service account created with comprehensive permissions${NC}"
echo -e "${GREEN}✅ GitHub repository access configured${NC}"
echo -e "${GREEN}✅ Cloud Storage bucket created: $BUCKET_NAME${NC}"
echo -e "${GREEN}✅ Secret Manager configured: $SECRET_NAME${NC}"
echo -e "${GREEN}✅ All required APIs enabled (Vertex AI, Gemini, etc.)${NC}"
echo ""
echo -e "${YELLOW}🔑 Next Steps:${NC}"
echo "1. Copy the secrets and variables above to your GitHub repository"
echo "2. Get your Gemini API key from https://aistudio.google.com/"
echo "3. Add your API key to Secret Manager:"
echo "   echo 'YOUR_API_KEY' | gcloud secrets versions add $SECRET_NAME --data-file=- --project=$PROJECT_ID"
echo "4. Add the same API key as GOOGLE_API_KEY secret in GitHub"
echo "5. Push to main branch or trigger the workflow manually"
echo ""
echo -e "${BLUE}📁 Summary saved to: $SUMMARY_FILE${NC}"
echo ""
echo -e "${GREEN}Your CI/CD pipeline should now work! 🚀${NC}"
