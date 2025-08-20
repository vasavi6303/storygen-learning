#!/bin/bash

# Script to update CI/CD workflow with configurable variables

echo "🔧 Updating CI/CD workflow to use variables..."

# Update .github/workflows/ci-cd.yml
CICD_FILE=".github/workflows/ci-cd.yml"

# Replace hardcoded repository names
sed -i 's/storygen-backend/\${{ env.ARTIFACT_REPO }}/g' "$CICD_FILE"
sed -i 's/storygen-frontend/\${{ env.ARTIFACT_REPO }}/g' "$CICD_FILE"

# Replace hardcoded regions
sed -i 's/us-central1/\${{ env.REGION }}/g' "$CICD_FILE"

# Replace hardcoded image references
sed -i 's/storygen-api-ws/\${{ env.BACKEND_IMAGE_NAME }}/g' "$CICD_FILE"
sed -i 's/storygen-frontend:/\${{ env.FRONTEND_IMAGE_NAME }}:/g' "$CICD_FILE"

# Replace hardcoded service names
sed -i 's/storygen-backend-ws-service/\${{ env.BACKEND_SERVICE_NAME }}/g' "$CICD_FILE"
sed -i 's/storygen-frontend/\${{ env.FRONTEND_SERVICE_NAME }}/g' "$CICD_FILE"

# Replace hardcoded bucket names
sed -i 's/genai-story-images/\${{ env.BUCKET_NAME }}/g' "$CICD_FILE"
sed -i 's/sdlc-468305-genmedia/\${{ env.BUCKET_NAME }}/g' "$CICD_FILE"

# Replace hardcoded secret names
sed -i 's/storygen-google-api-key/\${{ env.SECRET_NAME }}/g' "$CICD_FILE"

# Replace hardcoded resource values
sed -i 's/--memory=2Gi/--memory=\${{ env.BACKEND_MEMORY }}/g' "$CICD_FILE"
sed -i 's/--cpu=2/--cpu=\${{ env.BACKEND_CPU }}/g' "$CICD_FILE"
sed -i 's/--memory=1Gi/--memory=\${{ env.FRONTEND_MEMORY }}/g' "$CICD_FILE"
sed -i 's/--cpu=1/--cpu=\${{ env.FRONTEND_CPU }}/g' "$CICD_FILE"
sed -i 's/--min-instances=0/--min-instances=\${{ env.MIN_INSTANCES }}/g' "$CICD_FILE"
sed -i 's/--max-instances=2/--max-instances=\${{ env.MAX_INSTANCES }}/g' "$CICD_FILE"

echo "✅ CI/CD workflow updated with configurable variables"
