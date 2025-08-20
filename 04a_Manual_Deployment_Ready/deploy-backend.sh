#!/bin/bash
set -e

source ./deploy-env.sh

echo "🚀 Deploying StoryGen Backend..."

# Build and push backend image
echo "🔨 Building backend Docker image..."
cd backend

gcloud builds submit \
    --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${BACKEND_IMAGE_NAME}:latest \
    --project=$PROJECT_ID

echo "📦 Deploying backend to Cloud Run..."

# Deploy to Cloud Run with all necessary environment variables
gcloud run deploy $BACKEND_SERVICE_NAME \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${BACKEND_IMAGE_NAME}:latest \
    --platform=managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=8080 \
    --session-affinity \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}" \
    --set-env-vars="GOOGLE_CLOUD_PROJECT_ID=${PROJECT_ID}" \
    --set-env-vars="GENMEDIA_BUCKET=${BUCKET_NAME}" \
    --set-env-vars="GOOGLE_GENAI_USE_VERTEXAI=FALSE" \
    --set-env-vars="GOOGLE_CLOUD_REGION=${REGION}" \
    --set-env-vars="FRONTEND_URL=https://${FRONTEND_SERVICE_NAME}-7qwcxs6azq-uc.a.run.app" \
    --set-secrets="GOOGLE_API_KEY=storygen-google-api-key:latest" \
    --memory=2Gi \
    --cpu=2 \
    --min-instances=0 \
    --max-instances=2 \
    --project=$PROJECT_ID

# Get backend URL for frontend configuration
BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE_NAME \
    --platform=managed \
    --region=$REGION \
    --format="value(status.url)" \
    --project=$PROJECT_ID)

echo "✅ Backend deployed successfully!"
echo "🔗 Backend URL: $BACKEND_URL"

# Save backend URL for frontend deployment
echo "export BACKEND_URL=\"$BACKEND_URL\"" > ../backend-url.env

cd ..
