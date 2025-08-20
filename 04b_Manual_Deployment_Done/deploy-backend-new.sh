#!/bin/bash
set -e

# Load environment variables
source ./load-env.sh

echo "🚀 Deploying StoryGen Backend..."

# Build and push backend image
echo "🔨 Building backend Docker image..."
cd backend

BACKEND_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${BACKEND_IMAGE_NAME}:latest"

gcloud builds submit \
    --tag "$BACKEND_IMAGE_URL" \
    --project="$PROJECT_ID"

echo "📦 Deploying backend to Cloud Run..."

# Deploy to Cloud Run with all necessary environment variables
gcloud run deploy "$BACKEND_SERVICE_NAME" \
    --image="$BACKEND_IMAGE_URL" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated \
    --port=8080 \
    --session-affinity \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}" \
    --set-env-vars="GOOGLE_CLOUD_PROJECT_ID=${PROJECT_ID}" \
    --set-env-vars="GENMEDIA_BUCKET=${BUCKET_NAME}" \
    --set-env-vars="GOOGLE_GENAI_USE_VERTEXAI=${GOOGLE_GENAI_USE_VERTEXAI}" \
    --set-env-vars="GOOGLE_CLOUD_REGION=${REGION}" \
    --set-secrets="GOOGLE_API_KEY=${SECRET_NAME}:latest" \
    --memory="$BACKEND_MEMORY" \
    --cpu="$BACKEND_CPU" \
    --min-instances="$MIN_INSTANCES" \
    --max-instances="$MAX_INSTANCES" \
    --project="$PROJECT_ID"

# Get backend URL for frontend configuration
BACKEND_URL=$(gcloud run services describe "$BACKEND_SERVICE_NAME" \
    --platform=managed \
    --region="$REGION" \
    --format="value(status.url)" \
    --project="$PROJECT_ID")

echo "✅ Backend deployed successfully!"
echo "🔗 Backend URL: $BACKEND_URL"

# Save backend URL for frontend deployment
echo "export BACKEND_URL=\"$BACKEND_URL\"" > ../backend-url.env

cd ..

echo "📝 Backend URL saved to backend-url.env for frontend deployment"
