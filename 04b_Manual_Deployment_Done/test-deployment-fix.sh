#!/bin/bash
set -e

echo "🧪 Testing Deployment Fix"
echo "========================="

# Load environment variables
source ./load-env.sh

echo ""
echo "📋 Testing Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Backend Service: $BACKEND_SERVICE_NAME"
echo "   Frontend Service: $FRONTEND_SERVICE_NAME"
echo ""

# Test 1: Check if services are deployed
echo "🔍 Test 1: Checking service deployment status..."

BACKEND_STATUS=$(gcloud run services describe "$BACKEND_SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(status.conditions[0].status)" 2>/dev/null || echo "NotFound")

FRONTEND_STATUS=$(gcloud run services describe "$FRONTEND_SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(status.conditions[0].status)" 2>/dev/null || echo "NotFound")

if [ "$BACKEND_STATUS" = "True" ]; then
    echo "✅ Backend service is running"
else
    echo "❌ Backend service not found or not ready: $BACKEND_STATUS"
    exit 1
fi

if [ "$FRONTEND_STATUS" = "True" ]; then
    echo "✅ Frontend service is running"
else
    echo "❌ Frontend service not found or not ready: $FRONTEND_STATUS"
    exit 1
fi

# Test 2: Get service URLs
echo ""
echo "🔍 Test 2: Getting service URLs..."

BACKEND_URL=$(gcloud run services describe "$BACKEND_SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(status.url)")

FRONTEND_URL=$(gcloud run services describe "$FRONTEND_SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(status.url)")

echo "   Backend URL: $BACKEND_URL"
echo "   Frontend URL: $FRONTEND_URL"

# Test 3: Check backend health
echo ""
echo "🔍 Test 3: Testing backend health endpoint..."

HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" || echo "000")

if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "✅ Backend health check passed"
else
    echo "❌ Backend health check failed: HTTP $HEALTH_RESPONSE"
    echo "   Trying to get more details..."
    curl -s "$BACKEND_URL/health" || echo "   Connection failed"
fi

# Test 4: Check frontend configuration
echo ""
echo "🔍 Test 4: Checking frontend backend URL configuration..."

FRONTEND_BACKEND_URL=$(gcloud run services describe "$FRONTEND_SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(spec.template.spec.containers[0].env[?(@.name=='NEXT_PUBLIC_BACKEND_URL')].value)" 2>/dev/null || echo "")

if [ "$FRONTEND_BACKEND_URL" = "$BACKEND_URL" ]; then
    echo "✅ Frontend correctly configured with backend URL: $FRONTEND_BACKEND_URL"
else
    echo "⚠️ Frontend backend URL mismatch:"
    echo "   Expected: $BACKEND_URL"
    echo "   Configured: $FRONTEND_BACKEND_URL"
    echo "   This should be automatically fixed on next deployment"
fi

# Test 5: Test frontend accessibility
echo ""
echo "🔍 Test 5: Testing frontend accessibility..."

FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" || echo "000")

if [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend accessibility test failed: HTTP $FRONTEND_RESPONSE"
fi

# Test 6: Test WebSocket endpoint (basic connectivity)
echo ""
echo "🔍 Test 6: Testing WebSocket endpoint availability..."

WS_TEST_URL="${BACKEND_URL}/ws/test-connection"
WS_HTTP_URL="${WS_TEST_URL/wss:/https:}"
WS_HTTP_URL="${WS_HTTP_URL/ws:/http:}"

WS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$WS_HTTP_URL" || echo "000")

if [ "$WS_RESPONSE" = "426" ] || [ "$WS_RESPONSE" = "400" ]; then
    echo "✅ WebSocket endpoint is available (expected upgrade required response)"
elif [ "$WS_RESPONSE" = "404" ]; then
    echo "❌ WebSocket endpoint not found"
else
    echo "⚠️ WebSocket endpoint test inconclusive: HTTP $WS_RESPONSE"
fi

# Summary
echo ""
echo "📊 Test Summary:"
echo "================"

if [ "$BACKEND_STATUS" = "True" ] && [ "$FRONTEND_STATUS" = "True" ] && [ "$HEALTH_RESPONSE" = "200" ] && [ "$FRONTEND_RESPONSE" = "200" ]; then
    echo "✅ All critical tests passed!"
    echo ""
    echo "🌐 Your application should be accessible at:"
    echo "   Frontend: $FRONTEND_URL"
    echo "   Backend:  $BACKEND_URL"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Open the frontend URL in your browser"
    echo "   2. Test story generation functionality"
    echo "   3. Verify WebSocket connection shows as 'Connected'"
else
    echo "❌ Some tests failed. Please check the output above."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Ensure all prerequisites are met (run ./01-setup.sh)"
    echo "   2. Rebuild images (run ./02-build-images.sh)"
    echo "   3. Redeploy infrastructure (run ./03-deploy-infrastructure.sh)"
    echo "   4. Check Google Cloud Console for detailed error logs"
fi

echo ""
echo "📝 For detailed deployment information, see DEPLOYMENT_FIXES.md"
