# StoryGen Deployment Guide

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Terraform**: Install from [terraform.io](https://terraform.io)

3. **Google AI Studio API Key**: Get from [aistudio.google.com](https://aistudio.google.com)

## Quick Deployment

### Option 1: Complete Automated Deployment
```bash
chmod +x deploy-complete.sh
./deploy-complete.sh
```

### Option 2: Step-by-Step Deployment

1. **Setup environment**:
   ```bash
   source deploy-env.sh
   ```

2. **Setup Artifact Registry**:
   ```bash
   chmod +x setup-artifact-registry.sh
   ./setup-artifact-registry.sh
   ```

3. **Deploy infrastructure**:
   ```bash
   chmod +x deploy-infrastructure.sh
   ./deploy-infrastructure.sh
   ```

4. **Deploy backend**:
   ```bash
   chmod +x deploy-backend.sh
   ./deploy-backend.sh
   ```

5. **Deploy frontend**:
   ```bash
   chmod +x deploy-frontend.sh
   ./deploy-frontend.sh
   ```

## Post-Deployment Configuration

### Backend Environment Variables
The backend will be deployed with these environment variables:
- `GOOGLE_CLOUD_PROJECT`: Your GCP project ID
- `GOOGLE_CLOUD_PROJECT_ID`: Your GCP project ID (alternative name)
- `GENMEDIA_BUCKET`: Cloud Storage bucket for generated images
- `GOOGLE_GENAI_USE_VERTEXAI`: Set to TRUE for Vertex AI integration

### API Key Setup
After deployment, you may need to set up additional API keys:

1. **For Google AI Studio** (if not using Vertex AI):
   - Get API key from [aistudio.google.com](https://aistudio.google.com)
   - Update Cloud Run service environment variables

2. **For Vertex AI** (recommended for production):
   - Already configured through service account in Terraform
   - No additional setup required

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Vertex AI     │
│  (Next.js)      │◄──►│   (FastAPI)     │◄──►│   (Imagen)      │
│  Cloud Run      │    │   Cloud Run     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       
         │                       │                       
         └───────────────────────┼─────────────────────────
                                 │                       
                    ┌─────────────────┐                  
                    │ Cloud Storage   │                  
                    │ (Images)        │                  
                    └─────────────────┘                  
```

## Monitoring and Troubleshooting

### View Logs
```bash
# Backend logs
gcloud run services logs read genai-backend --region=us-central1 --project=sdlc-468305

# Frontend logs  
gcloud run services logs read genai-frontend --region=us-central1 --project=sdlc-468305
```

### Service URLs
```bash
# Get backend URL
gcloud run services describe genai-backend --region=us-central1 --format="value(status.url)" --project=sdlc-468305

# Get frontend URL
gcloud run services describe genai-frontend --region=us-central1 --format="value(status.url)" --project=sdlc-468305
```

### Common Issues

1. **Container build failures**: Check Cloud Build logs in Console
2. **WebSocket connection issues**: Verify backend URL configuration in frontend
3. **AI generation failures**: Check API key setup and quota limits
4. **Permission errors**: Verify service account IAM roles

## Cost Optimization

- **Development**: Services auto-scale to zero when not in use
- **Production**: Consider setting minimum instances for better response times
- **Storage**: Cloud Storage costs based on usage
- **AI**: Vertex AI charges per API call

## Security Considerations

- Services are deployed with `--allow-unauthenticated` for demo purposes
- For production, implement proper authentication
- Consider VPC-native deployments for additional security
- Regularly rotate API keys and service account keys
