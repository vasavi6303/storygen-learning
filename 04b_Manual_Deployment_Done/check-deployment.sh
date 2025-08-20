#!/bin/bash

echo "🏥 StoryGen Deployment Health Check"
echo "=================================="

# Load environment
source ./load-env.sh

echo ""
echo "🔍 Testing Service Health..."

# Get service URLs
BACKEND_URL=$(cd terraform_code && terraform output -raw backend-service_service_uri 2>/dev/null || echo "")
FRONTEND_URL=$(cd terraform_code && terraform output -raw frontend-service_service_uri 2>/dev/null || echo "")

if [ -z "$BACKEND_URL" ] || [ -z "$FRONTEND_URL" ]; then
    echo "❌ Could not get service URLs from Terraform"
    echo "   Please run ./03-deploy-infrastructure.sh first"
    exit 1
fi

echo "📡 Backend URL:  $BACKEND_URL"
echo "🌐 Frontend URL: $FRONTEND_URL"
echo ""

# Test backend health
echo "🔍 Testing backend health..."
if curl -f "$BACKEND_URL/health" -m 10 2>/dev/null; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    echo "   Checking backend logs..."
    gcloud run services logs read genai-backend --region="$REGION" --project="$PROJECT_ID" --limit=5
fi

echo ""

# Test frontend accessibility
echo "🔍 Testing frontend accessibility..."
if curl -f "$FRONTEND_URL" -m 10 -s -o /dev/null; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend is not accessible"
    echo "   Checking frontend logs..."
    gcloud run services logs read genai-frontend --region="$REGION" --project="$PROJECT_ID" --limit=5
fi

echo ""

# Test backend API
echo "🔍 Testing backend API endpoint..."
if curl -f "$BACKEND_URL/api/test" -m 10 -s -o /dev/null 2>/dev/null; then
    echo "✅ Backend API is responsive"
else
    echo "⚠️  Backend API test endpoint not responding (may be normal)"
fi

echo ""

# Check service configurations
echo "🔍 Checking service configurations..."

# Check backend memory
BACKEND_MEMORY=$(gcloud run services describe genai-backend --region="$REGION" --project="$PROJECT_ID" --format="value(spec.template.spec.containers[0].resources.limits.memory)" 2>/dev/null)
echo "📊 Backend Memory: $BACKEND_MEMORY"

# Check if secrets are configured
SECRET_CONFIG=$(gcloud run services describe genai-backend --region="$REGION" --project="$PROJECT_ID" --format="yaml" | grep -c "secretKeyRef" || echo "0")
if [ "$SECRET_CONFIG" -gt 0 ]; then
    echo "✅ Backend secrets configured"
else
    echo "⚠️  Backend secrets may not be configured"
fi

echo ""
echo "🎯 Deployment Summary:"
echo "   Backend:  $BACKEND_URL"
echo "   Frontend: $FRONTEND_URL"
echo ""
echo "🌐 Test your application:"
echo "   Open: $FRONTEND_URL"
