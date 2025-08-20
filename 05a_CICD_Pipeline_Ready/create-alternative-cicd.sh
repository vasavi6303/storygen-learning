#!/bin/bash

# Alternative CI/CD Setup - No GitHub Secrets Required
# This creates a workflow that hardcodes authentication values directly

set -e

PROJECT_ID="${1:-sdlcv1}"
GITHUB_USERNAME="${2:-cuppibla}"
REPO_NAME="${3:-storygeneration}"

echo "🔧 Creating alternative CI/CD workflow without GitHub secrets"
echo "Project: $PROJECT_ID"
echo "Repository: $GITHUB_USERNAME/$REPO_NAME"

# Get the project number and construct the values
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
WORKLOAD_IDENTITY_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
SERVICE_ACCOUNT_EMAIL="github-actions@$PROJECT_ID.iam.gserviceaccount.com"

# Create alternative workflow
cat > .github/workflows/ci-cd-no-secrets.yml << EOF
name: StoryGen CI/CD (No Secrets)

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  # HARDCODED authentication values (no secrets required)
  PROJECT_ID: "$PROJECT_ID"
  WORKLOAD_IDENTITY_PROVIDER: "$WORKLOAD_IDENTITY_PROVIDER"
  SERVICE_ACCOUNT_EMAIL: "$SERVICE_ACCOUNT_EMAIL"
  
  # Configurable values - use repository variables with defaults
  REGION: \${{ vars.GCP_REGION || 'us-central1' }}
  ARTIFACT_REPO: \${{ vars.ARTIFACT_REPO || 'storygen-repo' }}
  BACKEND_SERVICE_NAME: \${{ vars.BACKEND_SERVICE_NAME || 'genai-backend' }}
  FRONTEND_SERVICE_NAME: \${{ vars.FRONTEND_SERVICE_NAME || 'genai-frontend' }}
  BUCKET_NAME: \${{ vars.BUCKET_NAME || '$PROJECT_ID-story-images' }}
  SECRET_NAME: \${{ vars.SECRET_NAME || 'storygen-google-api-key' }}

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
            gcloud artifacts repositories create \${{ env.ARTIFACT_REPO }} \\
              --repository-format=docker \\
              --location=\${{ env.REGION }} \\
              --project=\${{ env.PROJECT_ID }}
          fi
          gcloud auth configure-docker \${{ env.REGION }}-docker.pkg.dev

  build-and-deploy:
    name: Build and Deploy
    runs-on: ubuntu-latest
    needs: setup-infrastructure
    permissions:
      contents: read
      id-token: write
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

      - name: Build and deploy backend
        run: |
          echo "🔨 Building and deploying backend..."
          cd backend
          gcloud builds submit \\
            --tag \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/storygen-backend:latest
          
          gcloud run deploy \${{ env.BACKEND_SERVICE_NAME }} \\
            --image=\${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/storygen-backend:latest \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --allow-unauthenticated \\
            --port=8080 \\
            --set-env-vars="GOOGLE_CLOUD_PROJECT=\${{ env.PROJECT_ID }}" \\
            --set-env-vars="GOOGLE_CLOUD_PROJECT_ID=\${{ env.PROJECT_ID }}" \\
            --set-env-vars="GENMEDIA_BUCKET=\${{ env.BUCKET_NAME }}" \\
            --set-env-vars="GOOGLE_GENAI_USE_VERTEXAI=FALSE" \\
            --set-env-vars="GOOGLE_CLOUD_REGION=\${{ env.REGION }}" \\
            --set-secrets="GOOGLE_API_KEY=\${{ env.SECRET_NAME }}:latest" \\
            --memory=2Gi \\
            --cpu=2 \\
            --project=\${{ env.PROJECT_ID }}

      - name: Build and deploy frontend  
        run: |
          echo "🌐 Building and deploying frontend..."
          cd frontend
          
          # Get backend URL
          BACKEND_URL=\$(gcloud run services describe \${{ env.BACKEND_SERVICE_NAME }} \\
            --region=\${{ env.REGION }} \\
            --format="value(status.url)" \\
            --project=\${{ env.PROJECT_ID }})
          
          docker build --build-arg NEXT_PUBLIC_BACKEND_URL="\$BACKEND_URL" \\
            -t \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/storygen-frontend:latest .
          
          docker push \${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/storygen-frontend:latest
          
          gcloud run deploy \${{ env.FRONTEND_SERVICE_NAME }} \\
            --image=\${{ env.REGION }}-docker.pkg.dev/\${{ env.PROJECT_ID }}/\${{ env.ARTIFACT_REPO }}/storygen-frontend:latest \\
            --platform=managed \\
            --region=\${{ env.REGION }} \\
            --allow-unauthenticated \\
            --port=3000 \\
            --set-env-vars="NEXT_PUBLIC_BACKEND_URL=\$BACKEND_URL" \\
            --memory=1Gi \\
            --cpu=1 \\
            --project=\${{ env.PROJECT_ID }}

      - name: Display URLs
        run: |
          echo "🎉 Deployment complete!"
          echo "Backend: \$(gcloud run services describe \${{ env.BACKEND_SERVICE_NAME }} --region=\${{ env.REGION }} --format='value(status.url)')"
          echo "Frontend: \$(gcloud run services describe \${{ env.FRONTEND_SERVICE_NAME }} --region=\${{ env.REGION }} --format='value(status.url)')"
EOF

echo ""
echo "✅ Alternative CI/CD workflow created!"
echo ""
echo "📋 This workflow requires:"
echo "1. NO GitHub secrets! ✅"
echo "2. Only GitHub variables (optional):"
echo "   - GCP_REGION: us-central1" 
echo "   - ARTIFACT_REPO: storygen-repo"
echo "   - BACKEND_SERVICE_NAME: genai-backend"
echo "   - FRONTEND_SERVICE_NAME: genai-frontend"
echo "   - BUCKET_NAME: $PROJECT_ID-story-images"
echo "   - SECRET_NAME: storygen-google-api-key"
echo ""
echo "🚀 To use this workflow:"
echo "1. Add your Gemini API key to Secret Manager:"
echo "   echo 'YOUR_API_KEY' | gcloud secrets versions add storygen-google-api-key --data-file=- --project=$PROJECT_ID"
echo "2. Rename the workflow file:"
echo "   mv .github/workflows/ci-cd-no-secrets.yml .github/workflows/ci-cd.yml"
echo "3. Push to main branch"
echo ""
echo "✅ All authentication values are hardcoded in the workflow - no secrets needed!"
