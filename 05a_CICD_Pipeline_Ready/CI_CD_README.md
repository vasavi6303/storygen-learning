# StoryGen CI/CD Pipeline

## 🚀 Complete Fork-Friendly CI/CD

This repository includes a comprehensive CI/CD pipeline that automatically deploys the complete StoryGen application to Google Cloud Platform.

### ✨ Features

- 🔄 **Fully Automated**: Complete infrastructure setup and application deployment
- 🍴 **Fork-Friendly**: Works out-of-the-box for new users who fork the repo
- 🔐 **Secure**: Uses Workload Identity and Secret Manager for secure authentication
- 🏗️ **Infrastructure as Code**: Terraform manages all cloud resources
- ✅ **Validated**: Includes health checks and deployment verification
- 📊 **Configurable**: Uses repository variables for easy customization

### 🏗️ What Gets Deployed

The CI/CD pipeline creates a complete production environment:

```
┌─────────────────────────────────────────────────────────────┐
│                   Google Cloud Project                     │
├─────────────────────────────────────────────────────────────┤
│  🏗️ Infrastructure (Terraform)                             │
│  ├── Cloud Run Services (Backend + Frontend)               │
│  ├── Artifact Registry (Docker Images)                     │
│  ├── Cloud Storage (Generated Images)                      │
│  ├── Secret Manager (API Keys)                             │
│  ├── IAM Roles & Service Accounts                          │
│  └── Enabled APIs (Run, Build, AI Platform, etc.)         │
│                                                             │
│  🔧 Backend Service                                         │
│  ├── FastAPI + WebSocket Server                            │
│  ├── Google ADK Integration                                │
│  ├── Story & Image Generation                              │
│  └── Environment: GOOGLE_API_KEY, Storage, etc.           │
│                                                             │
│  🌐 Frontend Service                                        │
│  ├── Next.js Application                                   │
│  ├── Real-time WebSocket Client                            │
│  ├── Responsive UI                                         │
│  └── Environment: Backend URL configured                   │
└─────────────────────────────────────────────────────────────┘
```

### 🎯 Pipeline Stages

The CI/CD pipeline runs in 4 sequential stages:

#### 1. 🏗️ **Setup Infrastructure**
- Validates required secrets and variables
- Enables Google Cloud APIs
- Creates Artifact Registry repositories
- Sets up Secret Manager with API keys
- Deploys Terraform infrastructure
- Outputs service URLs for subsequent stages

#### 2. 🔨 **Build & Deploy Backend**
- Builds backend Docker image using Cloud Build
- Pushes to Artifact Registry
- Deploys to Cloud Run with full configuration:
  - Environment variables (project, region, bucket)
  - Secret injection (Google API key)
  - Resource limits (2Gi memory, 2 CPU)
  - WebSocket support (session affinity)
  - Auto-scaling (0-2 instances)

#### 3. 🌐 **Build & Deploy Frontend**
- Builds frontend with backend URL configuration
- Pushes to Artifact Registry
- Deploys to Cloud Run with:
  - Backend URL environment variable
  - Resource limits (1Gi memory, 1 CPU)
  - Auto-scaling (0-2 instances)

#### 4. ✅ **Health Check & Validation**
- Tests backend `/health` endpoint
- Validates frontend accessibility
- Provides deployment summary with URLs
- Outputs troubleshooting information

### 🔧 Configuration

The pipeline is highly configurable using GitHub repository variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GCP_PROJECT_ID` | `your-gcp-project-id` | Google Cloud Project ID |
| `GCP_REGION` | `us-central1` | Deployment region |
| `ARTIFACT_REPO` | `storygen-repo` | Docker repository name |
| `BACKEND_SERVICE_NAME` | `genai-backend` | Backend Cloud Run service |
| `FRONTEND_SERVICE_NAME` | `genai-frontend` | Frontend Cloud Run service |
| `BACKEND_IMAGE_NAME` | `storygen-backend` | Backend Docker image |
| `FRONTEND_IMAGE_NAME` | `storygen-frontend` | Frontend Docker image |
| `BUCKET_NAME` | `genai-story-images` | Cloud Storage bucket |
| `SECRET_NAME` | `storygen-google-api-key` | Secret Manager secret |

### 🔐 Required Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `WORKLOAD_IDENTITY_PROVIDER` | GitHub→GCP authentication | See FORK_SETUP.md |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Service account for deployments | `github-actions@PROJECT_ID.iam.gserviceaccount.com` |
| `GOOGLE_API_KEY` | Google AI Studio API key | [aistudio.google.com](https://aistudio.google.com/) |

### 🚀 Quick Start

1. **Fork this repository**
2. **Follow [FORK_SETUP.md](./FORK_SETUP.md)** for detailed setup
3. **Push to main branch** or trigger workflow manually
4. **Access your deployed app** (URLs provided in workflow output)

### 📋 Service Naming Consistency

The CI/CD pipeline uses **consistent naming** with manual deployment scripts:

| Component | Service Name | Repository | Image |
|-----------|--------------|------------|-------|
| Backend | `genai-backend` | `storygen-repo` | `storygen-backend` |
| Frontend | `genai-frontend` | `storygen-repo` | `storygen-frontend` |

This ensures compatibility between manual deployment and CI/CD approaches.

### 🔍 Monitoring & Debugging

#### View Logs
```bash
# Backend logs
gcloud run services logs read genai-backend --region=us-central1 --project=YOUR_PROJECT

# Frontend logs  
gcloud run services logs read genai-frontend --region=us-central1 --project=YOUR_PROJECT
```

#### Check Service Status
```bash
# List services
gcloud run services list --project=YOUR_PROJECT

# Get service details
gcloud run services describe genai-backend --region=us-central1 --project=YOUR_PROJECT
```

#### Access Services
The pipeline outputs service URLs, but you can also get them:
```bash
# Backend URL
gcloud run services describe genai-backend --region=us-central1 --format="value(status.url)" --project=YOUR_PROJECT

# Frontend URL
gcloud run services describe genai-frontend --region=us-central1 --format="value(status.url)" --project=YOUR_PROJECT
```

### 🛠️ Customization Examples

#### Deploy to Different Region
```yaml
# Set repository variable
GCP_REGION: europe-west1
```

#### Custom Service Names
```yaml
# Set repository variables
BACKEND_SERVICE_NAME: my-story-backend
FRONTEND_SERVICE_NAME: my-story-frontend
```

#### Different Resource Limits
Modify the CI/CD workflow `deploy` steps:
```yaml
--memory=4Gi --cpu=4  # More resources
--min-instances=1     # Always-on instances
```

### 🔄 Triggering Deployments

#### Automatic
- Every push to `main` branch triggers full deployment

#### Manual
- Go to Actions tab → "StoryGen CI/CD - Complete Deployment" → "Run workflow"

#### Partial Redeployment
For code-only changes without infrastructure updates:
1. Comment out the `setup-infrastructure` job dependencies
2. Run workflow manually

### 🎯 Benefits vs Manual Deployment

| Aspect | Manual Deployment | CI/CD Pipeline |
|--------|------------------|----------------|
| **Setup Time** | 15-20 minutes | 5 minutes (one-time setup) |
| **Consistency** | Manual steps, possible errors | Automated, repeatable |
| **Security** | Local credentials | Workload Identity (secure) |
| **Scalability** | One-off deployment | Every commit deploys |
| **Validation** | Manual verification | Automated health checks |
| **Documentation** | Multiple scripts | Single workflow file |

### 🚨 Troubleshooting

Common issues and solutions:

#### Authentication Failed
```
Error: google: could not find default credentials
```
**Solution**: Check Workload Identity Provider setup in secrets

#### API Not Enabled
```
Error: API [service] not enabled
```
**Solution**: Pipeline auto-enables APIs, but check GCP console if needed

#### Resource Quota Exceeded
```
Error: Quota exceeded for resource
```
**Solution**: Request quota increase in GCP console

#### Build Timeout
```
Error: Build timeout
```
**Solution**: Increase timeout in workflow or optimize Dockerfile

For detailed troubleshooting, see [FORK_SETUP.md](./FORK_SETUP.md).

### 📚 Related Documentation

- 📖 [FORK_SETUP.md](./FORK_SETUP.md) - Complete setup guide for forked repositories
- 📖 [DEPLOYMENT.md](./DEPLOYMENT.md) - Manual deployment instructions
- 📖 [README.md](./README.md) - Project overview and features
- 📖 [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Local development setup

---

**Ready to deploy?** Follow the [Fork Setup Guide](./FORK_SETUP.md) to get your CI/CD pipeline running in 5 minutes! 🚀
