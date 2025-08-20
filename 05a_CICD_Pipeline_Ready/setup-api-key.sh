#!/bin/bash

# 🔐 StoryGen API Key Setup Script
# ================================
# This script securely adds your Gemini API key to Google Cloud Secret Manager
# 
# Prerequisites:
# 1. Run ./setup-direct.sh first to configure your project
# 2. Get your API key from https://aistudio.google.com/
#
# Usage:
#   ./setup-api-key.sh [PROJECT_ID] [SECRET_NAME]
#
# Examples:
#   ./setup-api-key.sh                    # Interactive prompts
#   ./setup-api-key.sh sdlcv1             # Uses default secret name
#   ./setup-api-key.sh sdlcv1 my-api-key  # Custom secret name

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔐 StoryGen API Key Setup${NC}"
echo -e "${CYAN}=========================${NC}"
echo ""
echo "This script will securely store your Gemini API key in Google Cloud Secret Manager."
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
    echo "Please install: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI found${NC}"

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
    echo -e "${RED}❌ Not authenticated with gcloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
echo -e "${GREEN}✅ Authenticated as: ${CURRENT_ACCOUNT}${NC}"

# Get configuration
if [ -n "$1" ]; then
    PROJECT_ID="$1"
else
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        echo "Current project: $CURRENT_PROJECT"
        read -p "Use current project? (y/N): " use_current
        if [[ $use_current =~ ^[Yy]$ ]]; then
            PROJECT_ID="$CURRENT_PROJECT"
        else
            read -p "Google Cloud Project ID: " PROJECT_ID
        fi
    else
        read -p "Google Cloud Project ID: " PROJECT_ID
    fi
fi

if [ -n "$2" ]; then
    SECRET_NAME="$2"
else
    SECRET_NAME="storygen-google-api-key"
fi

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Project: $PROJECT_ID"
echo "  Secret Name: $SECRET_NAME"
echo ""

# Validate project access
echo "🔍 Validating project access..."
if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${RED}❌ Project '$PROJECT_ID' not accessible or doesn't exist${NC}"
    echo "Please check the project ID and ensure you have access."
    echo "Did you run ./setup-direct.sh first?"
    exit 1
fi
echo -e "${GREEN}✅ Project '$PROJECT_ID' is accessible${NC}"

# Check if Secret Manager API is enabled
echo "🔍 Checking Secret Manager API..."
if ! gcloud services list --enabled --filter="name:secretmanager.googleapis.com" --format="value(name)" --project="$PROJECT_ID" | grep -q "secretmanager.googleapis.com"; then
    echo -e "${YELLOW}⚠️ Secret Manager API not enabled. Enabling now...${NC}"
    gcloud services enable secretmanager.googleapis.com --project="$PROJECT_ID"
    echo -e "${GREEN}✅ Secret Manager API enabled${NC}"
else
    echo -e "${GREEN}✅ Secret Manager API is enabled${NC}"
fi

# Check if secret exists
echo ""
echo "🔍 Checking if secret exists..."
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ Secret '$SECRET_NAME' already exists${NC}"
    read -p "Update existing secret with new API key? (y/N): " update_secret
    if [[ ! $update_secret =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
    UPDATING=true
else
    echo -e "${GREEN}✅ Secret '$SECRET_NAME' will be created${NC}"
    UPDATING=false
fi

# Get API key
echo ""
echo -e "${YELLOW}🔑 API Key Input${NC}"
echo "==============="
echo "Get your Gemini API key from: https://aistudio.google.com/"
echo ""
echo -e "${YELLOW}⚠️ Your API key will not be displayed for security${NC}"
read -s -p "Enter your Gemini API key: " API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ No API key provided${NC}"
    exit 1
fi

# Validate API key format (basic check)
if [ ${#API_KEY} -lt 20 ]; then
    echo -e "${RED}❌ API key seems too short. Please check and try again.${NC}"
    exit 1
fi

# Create or update secret
echo ""
if [ "$UPDATING" = true ]; then
    echo "🔄 Updating existing secret..."
    echo -n "$API_KEY" | gcloud secrets versions add "$SECRET_NAME" \
        --data-file=- \
        --project="$PROJECT_ID"
    echo -e "${GREEN}✅ Secret updated successfully${NC}"
else
    echo "🔐 Creating new secret..."
    # Create secret first
    gcloud secrets create "$SECRET_NAME" \
        --replication-policy="automatic" \
        --project="$PROJECT_ID"
    
    # Add the API key
    echo -n "$API_KEY" | gcloud secrets versions add "$SECRET_NAME" \
        --data-file=- \
        --project="$PROJECT_ID"
    echo -e "${GREEN}✅ Secret created successfully${NC}"
fi

# Test secret access
echo ""
echo "🧪 Testing secret access..."
if gcloud secrets versions access latest --secret="$SECRET_NAME" --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Secret is accessible${NC}"
else
    echo -e "${RED}❌ Secret access test failed${NC}"
    exit 1
fi

# Clean up and customize workflows
echo ""
echo -e "${BLUE}🔧 Setting up personalized CI/CD workflow${NC}"
echo "========================================"

# Get project number for Workload Identity Provider
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider-fixed"
SERVICE_ACCOUNT_EMAIL="github-actions@$PROJECT_ID.iam.gserviceaccount.com"

# Back up existing workflows
echo "📦 Backing up original workflows..."
mkdir -p .github/workflows/backup
mv .github/workflows/ci-cd.yml .github/workflows/backup/ci-cd-original.yml 2>/dev/null || true
mv .github/workflows/ci-cd-new.yml .github/workflows/backup/ 2>/dev/null || true
mv .github/workflows/ci-cd-no-secrets.yml .github/workflows/backup/ 2>/dev/null || true

# Create personalized CI/CD workflow (full 4-stage version)
echo "🔄 Creating personalized CI/CD workflow..."
cat > .github/workflows/ci-cd.yml << EOF
name: StoryGen CI/CD

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  # PROJECT-SPECIFIC authentication values (auto-configured)
  PROJECT_ID: "$PROJECT_ID"
  WORKLOAD_IDENTITY_PROVIDER: "$WORKLOAD_IDENTITY_PROVIDER"
  SERVICE_ACCOUNT_EMAIL: "$SERVICE_ACCOUNT_EMAIL"
  
  # Configurable values - use repository variables with defaults
  REGION: \${{ vars.GCP_REGION || 'us-central1' }}
  ARTIFACT_REPO: \${{ vars.ARTIFACT_REPO || 'storygen-repo' }}
  BACKEND_SERVICE_NAME: \${{ vars.BACKEND_SERVICE_NAME || 'genai-backend' }}
  FRONTEND_SERVICE_NAME: \${{ vars.FRONTEND_SERVICE_NAME || 'genai-frontend' }}
  BACKEND_IMAGE_NAME: \${{ vars.BACKEND_IMAGE_NAME || 'storygen-backend' }}
  FRONTEND_IMAGE_NAME: \${{ vars.FRONTEND_IMAGE_NAME || 'storygen-frontend' }}
  BUCKET_NAME: \${{ vars.BUCKET_NAME || '$PROJECT_ID-story-images' }}
  SECRET_NAME: \${{ vars.SECRET_NAME || '$SECRET_NAME' }}
  BACKEND_MEMORY: \${{ vars.BACKEND_MEMORY || '2Gi' }}
  BACKEND_CPU: \${{ vars.BACKEND_CPU || '2' }}
  FRONTEND_MEMORY: \${{ vars.FRONTEND_MEMORY || '1Gi' }}
  FRONTEND_CPU: \${{ vars.FRONTEND_CPU || '1' }}
  MIN_INSTANCES: \${{ vars.MIN_INSTANCES || '0' }}
  MAX_INSTANCES: \${{ vars.MAX_INSTANCES || '2' }}

jobs:
  setup-infrastructure:
    name: Setup Infrastructure
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Validate configuration
        run: |
          echo "🔍 Validating configuration..."
          echo "✅ Configuration:"
          echo "  Project ID: \${{ env.PROJECT_ID }}"
          echo "  Region: \${{ env.REGION }}"
          echo "  Service Account: \${{ env.SERVICE_ACCOUNT_EMAIL }}"
          echo "  Backend Service: \${{ env.BACKEND_SERVICE_NAME }}"
          echo "  Frontend Service: \${{ env.FRONTEND_SERVICE_NAME }}"

      - name: Authenticate with Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ env.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: \${{ env.SERVICE_ACCOUNT_EMAIL }}
          project_id: \${{ env.PROJECT_ID }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
        with:
          project_id: \${{ env.PROJECT_ID }}

      - name: Enable required APIs
        run: |
          echo "🔧 Enabling required Google Cloud APIs..."
          gcloud services enable \\
            run.googleapis.com \\
            cloudbuild.googleapis.com \\
            artifactregistry.googleapis.com \\
            aiplatform.googleapis.com \\
            storage.googleapis.com \\
            secretmanager.googleapis.com \\
            --project=\${{ env.PROJECT_ID }}

      - name: Setup Artifact Registry
        run: |
          echo "🏗️ Setting up Artifact Registry..."
          if ! gcloud artifacts repositories describe \${{ env.ARTIFACT_REPO }} \\
               --location=\${{ env.REGION }} \\
               --project=\${{ env.PROJECT_ID }} &>/dev/null; then
            echo "Creating Artifact Registry repository..."
            gcloud artifacts repositories create \${{ env.ARTIFACT_REPO }} \\
              --repository-format=docker \\
              --location=\${{ env.REGION }} \\
              --description="Docker repository for StoryGen application" \\
              --project=\${{ env.PROJECT_ID }}
          else
            echo "✅ Artifact Registry repository already exists"
          fi
          gcloud auth configure-docker \${{ env.REGION }}-docker.pkg.dev

      - name: Setup Secret Manager
        run: |
          echo "🔐 Setting up Secret Manager..."
          if ! gcloud secrets describe \${{ env.SECRET_NAME }} \\
               --project=\${{ env.PROJECT_ID }} &>/dev/null; then
            echo "Creating secret for Google API key..."
            gcloud secrets create \${{ env.SECRET_NAME }} \\
              --replication-policy="automatic" \\
              --project=\${{ env.PROJECT_ID }}
          else
            echo "✅ Secret Manager secret already exists"
          fi

  build-and-deploy-backend:
    name: Build and Deploy Backend
    runs-on: ubuntu-latest
    needs: setup-infrastructure
    permissions:
      contents: read
      id-token: write
    outputs:
      backend-url: \${{ steps.deploy-backend.outputs.backend-url }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate with Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ env.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: \${{ env.SERVICE_ACCOUNT_EMAIL }}
          project_id: \${{ env.PROJECT_ID }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
        with:
          project_id: \${{ env.PROJECT_ID }}

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker \${{ env.REGION }}-docker.pkg.dev

      - name: Build and push backend Docker image
        run: |
          echo "🔨 Building backend Docker image..."
          cd backend
          gcloud builds submit \\
            --tag \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/\${{ env.BACKEND_IMAGE_NAME }}:latest \\
            --project=\${{ env.PROJECT_ID }}
          echo "✅ Backend image built and pushed successfully"

      - name: Deploy backend to Cloud Run
        id: deploy-backend
        run: |
          echo "📦 Deploying backend to Cloud Run..."
          FRONTEND_URL="https://\${{ env.FRONTEND_SERVICE_NAME }}-\${{ env.PROJECT_ID }}.\${{ env.REGION }}.run.app"
          
          gcloud run deploy \${{ env.BACKEND_SERVICE_NAME }} \\
            --image=\${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/\${{ env.BACKEND_IMAGE_NAME }}:latest \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --allow-unauthenticated \\
            --port=8080 \\
            --session-affinity \\
            --set-env-vars="GOOGLE_CLOUD_PROJECT=\${{ env.PROJECT_ID }}" \\
            --set-env-vars="GOOGLE_CLOUD_PROJECT_ID=\${{ env.PROJECT_ID }}" \\
            --set-env-vars="GENMEDIA_BUCKET=\${{ env.BUCKET_NAME }}" \\
            --set-env-vars="GOOGLE_GENAI_USE_VERTEXAI=FALSE" \\
            --set-env-vars="GOOGLE_CLOUD_REGION=\${{ env.REGION }}" \\
            --set-env-vars="FRONTEND_URL=\$FRONTEND_URL" \\
            --set-secrets="GOOGLE_API_KEY=\${{ env.SECRET_NAME }}:latest" \\
            --memory=\${{ env.BACKEND_MEMORY }} \\
            --cpu=\${{ env.BACKEND_CPU }} \\
            --min-instances=\${{ env.MIN_INSTANCES }} \\
            --max-instances=\${{ env.MAX_INSTANCES }} \\
            --project=\${{ env.PROJECT_ID }}

          BACKEND_URL=\$(gcloud run services describe \${{ env.BACKEND_SERVICE_NAME }} \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --format="value(status.url)" \\
            --project=\${{ env.PROJECT_ID }})

          echo "✅ Backend deployed successfully!"
          echo "🔗 Backend URL: \$BACKEND_URL"
          echo "backend-url=\$BACKEND_URL" >> \$GITHUB_OUTPUT

  build-and-deploy-frontend:
    name: Build and Deploy Frontend
    runs-on: ubuntu-latest
    needs: [setup-infrastructure, build-and-deploy-backend]
    permissions:
      contents: read
      id-token: write
    outputs:
      frontend-url: \${{ steps.deploy-frontend.outputs.frontend-url }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate with Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ env.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: \${{ env.SERVICE_ACCOUNT_EMAIL }}
          project_id: \${{ env.PROJECT_ID }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
        with:
          project_id: \${{ env.PROJECT_ID }}

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker \${{ env.REGION }}-docker.pkg.dev

      - name: Build and push frontend Docker image
        run: |
          echo "🔨 Building frontend Docker image..."
          BACKEND_URL="\${{ needs.build-and-deploy-backend.outputs.backend-url }}"
          echo "🔗 Using backend URL: \$BACKEND_URL"
          
          cd frontend
          docker build \\
            --build-arg NEXT_PUBLIC_BACKEND_URL="\$BACKEND_URL" \\
            -t \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/\${{ env.FRONTEND_IMAGE_NAME }}:latest .
          
          docker push \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/\${{ env.FRONTEND_IMAGE_NAME }}:latest
          echo "✅ Frontend image built and pushed successfully"

      - name: Deploy frontend to Cloud Run
        id: deploy-frontend
        run: |
          echo "🚀 Deploying frontend to Cloud Run..."
          BACKEND_URL="\${{ needs.build-and-deploy-backend.outputs.backend-url }}"
          
          gcloud run deploy \${{ env.FRONTEND_SERVICE_NAME }} \\
            --image=\${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/\${{ env.FRONTEND_IMAGE_NAME }}:latest \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --allow-unauthenticated \\
            --port=3000 \\
            --set-env-vars="NEXT_PUBLIC_BACKEND_URL=\$BACKEND_URL" \\
            --memory=\${{ env.FRONTEND_MEMORY }} \\
            --cpu=\${{ env.FRONTEND_CPU }} \\
            --min-instances=\${{ env.MIN_INSTANCES }} \\
            --max-instances=\${{ env.MAX_INSTANCES }} \\
            --project=\${{ env.PROJECT_ID }}

          FRONTEND_URL=\$(gcloud run services describe \${{ env.FRONTEND_SERVICE_NAME }} \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --format="value(status.url)" \\
            --project=\${{ env.PROJECT_ID }})

          echo "✅ Frontend deployed successfully!"
          echo "🌐 Frontend URL: \$FRONTEND_URL"
          echo "frontend-url=\$FRONTEND_URL" >> \$GITHUB_OUTPUT

  health-check:
    name: Health Check & Validation
    runs-on: ubuntu-latest
    needs: [build-and-deploy-backend, build-and-deploy-frontend]
    permissions:
      contents: read
    steps:
      - name: Test Backend Health
        run: |
          echo "🏥 Testing backend health..."
          BACKEND_URL="\${{ needs.build-and-deploy-backend.outputs.backend-url }}"
          
          if [ -z "\$BACKEND_URL" ]; then
            echo "❌ Backend URL not available"
            exit 1
          fi
          
          echo "Testing backend at: \$BACKEND_URL"
          for i in {1..5}; do
            echo "Attempt \$i/5..."
            HEALTH_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" "\$BACKEND_URL/health" || echo "000")
            
            if [ "\$HEALTH_RESPONSE" = "200" ]; then
              echo "✅ Backend health check passed"
              curl -s "\$BACKEND_URL/health"
              break
            else
              echo "⚠️ Backend health check failed (HTTP \$HEALTH_RESPONSE)"
              if [ \$i -eq 5 ]; then
                echo "❌ Backend health check failed after 5 attempts"
                exit 1
              fi
              echo "Retrying in 30 seconds..."
              sleep 30
            fi
          done

      - name: Test Frontend Accessibility
        run: |
          echo "🌐 Testing frontend accessibility..."
          FRONTEND_URL="\${{ needs.build-and-deploy-frontend.outputs.frontend-url }}"
          
          if [ -z "\$FRONTEND_URL" ]; then
            echo "❌ Frontend URL not available"
            exit 1
          fi
          
          echo "Testing frontend at: \$FRONTEND_URL"
          FRONTEND_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" "\$FRONTEND_URL" || echo "000")
          
          if [ "\$FRONTEND_RESPONSE" = "200" ]; then
            echo "✅ Frontend accessibility check passed"
          else
            echo "❌ Frontend accessibility check failed (HTTP \$FRONTEND_RESPONSE)"
            echo "Retrying in 30 seconds..."
            sleep 30
            FRONTEND_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" "\$FRONTEND_URL" || echo "000")
            if [ "\$FRONTEND_RESPONSE" = "200" ]; then
              echo "✅ Frontend accessibility check passed on retry"
            else
              echo "❌ Frontend accessibility check failed on retry (HTTP \$FRONTEND_RESPONSE)"
              exit 1
            fi
          fi

      - name: Display Deployment Summary
        run: |
          echo ""
          echo "🎉 Deployment Complete!"
          echo "======================="
          echo ""
          echo "📋 Configuration Used:"
          echo "  Project ID: \${{ env.PROJECT_ID }}"
          echo "  Region: \${{ env.REGION }}"
          echo "  Backend Service: \${{ env.BACKEND_SERVICE_NAME }}"
          echo "  Frontend Service: \${{ env.FRONTEND_SERVICE_NAME }}"
          echo ""
          echo "📋 Service URLs:"
          echo "🔗 Backend:  \${{ needs.build-and-deploy-backend.outputs.backend-url }}"
          echo "🌐 Frontend: \${{ needs.build-and-deploy-frontend.outputs.frontend-url }}"
          echo ""
          echo "📋 Next Steps:"
          echo "1. Visit your application at the Frontend URL"
          echo "2. Verify the connection indicator shows 'Connected'"
          echo "3. Test story generation functionality"
EOF

echo -e "${GREEN}✅ Personalized CI/CD workflow created for project: $PROJECT_ID${NC}"

echo ""
echo -e "${CYAN}🎉 API Key Setup Complete!${NC}"
echo -e "${CYAN}===========================${NC}"
echo ""
echo -e "${GREEN}✅ Gemini API key securely stored in Secret Manager${NC}"
echo -e "${GREEN}✅ Project: $PROJECT_ID${NC}"
echo -e "${GREEN}✅ Secret: $SECRET_NAME${NC}"
echo -e "${GREEN}✅ CI/CD workflow optimized${NC}"
echo ""
echo -e "${BLUE}🚀 Ready for CI/CD!${NC}"
echo "==================="
echo "Your setup is now complete. The CI/CD pipeline will:"
echo "1. ✅ Authenticate securely using Workload Identity"
echo "2. ✅ Access your API key from Secret Manager"
echo "3. ✅ Deploy your StoryGen application automatically"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Push your code to the main branch"
echo "2. Watch the deployment in GitHub Actions"
echo "3. Access your deployed app (URLs will be shown in workflow output)"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "• View deployment: Go to your GitHub repo → Actions tab"
echo "• Update API key: Run this script again anytime"
echo "• Check secret: gcloud secrets versions access latest --secret=$SECRET_NAME --project=$PROJECT_ID"
echo ""
echo -e "${GREEN}🎯 Your StoryGen is ready to deploy! 🚀${NC}"
