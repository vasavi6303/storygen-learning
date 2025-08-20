#!/bin/bash
set -e

source ./deploy-env.sh

# Load backend URL from previous deployment
if [ -f "./backend-url.env" ]; then
    source ./backend-url.env
    echo "📡 Using backend URL: $BACKEND_URL"
else
    echo "❌ Backend URL not found. Please deploy backend first."
    exit 1
fi

echo "🚀 Deploying StoryGen Frontend..."

cd frontend

# Create a build-time environment file for Next.js
cat > .env.local << EOF
NEXT_PUBLIC_BACKEND_URL=${BACKEND_URL}
EOF

echo "🔨 Building frontend Docker image with backend URL..."

# Build the frontend image with the backend URL as a build arg
gcloud builds submit \
    --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${FRONTEND_IMAGE_NAME}:latest \
    --project=$PROJECT_ID

echo "📦 Deploying frontend to Cloud Run..."

# Deploy frontend to Cloud Run
gcloud run deploy $FRONTEND_SERVICE_NAME \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${FRONTEND_IMAGE_NAME}:latest \
    --platform=managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=3000 \
    --set-env-vars="NEXT_PUBLIC_BACKEND_URL=${BACKEND_URL}" \
    --memory=1Gi \
    --cpu=1 \
    --min-instances=0 \
    --max-instances=1 \
    --project=$PROJECT_ID

# Get frontend URL
FRONTEND_URL=$(gcloud run services describe $FRONTEND_SERVICE_NAME \
    --platform=managed \
    --region=$REGION \
    --format="value(status.url)" \
    --project=$PROJECT_ID)

echo "✅ Frontend deployed successfully!"
echo "🌐 Frontend URL: $FRONTEND_URL"
echo "📡 Backend URL: $BACKEND_URL"

cd ..
