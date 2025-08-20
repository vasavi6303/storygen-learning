# 🚀 Portable StoryGen Deployment Guide

## Overview

StoryGen is now **fully portable** and can be deployed to any Google Cloud project with minimal configuration. No more hardcoded values!

## 🎯 Quick Start (2 Minutes)

### Option 1: Automated Setup
```bash
# Clone the repository
git clone <your-fork-url>
cd storygen-main

# Run the automated setup script
./setup-new-project.sh
```

The script will:
- ✅ Prompt for your project configuration
- ✅ Create `config.env` with your settings
- ✅ Create `terraform_code/input.tfvars`
- ✅ Validate your Google Cloud setup
- ✅ Provide next steps for deployment

### Option 2: Manual Configuration

1. **Copy configuration files:**
   ```bash
   cp config.example.env config.env
   cp terraform_code/input.tfvars.example terraform_code/input.tfvars
   ```

2. **Edit `config.env`:**
   ```bash
   # Required: Your Google Cloud Project ID
   PROJECT_ID=sdlcv1

   # Optional: Customize other settings
   REGION=us-central1
   BACKEND_SERVICE_NAME=genai-backend
   FRONTEND_SERVICE_NAME=genai-frontend
   # ... other settings with defaults
   ```

3. **Edit `terraform_code/input.tfvars`:**
   ```hcl
   # Required: Your Google Cloud Project ID
   project_id = "sdlcv1"

   # Optional: Customize other settings
   region = "us-central1"
   # ... other settings
   ```

## 📋 Configuration Variables

### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_ID` | Your Google Cloud Project ID | `sdlcv1` |

### Optional Variables (with defaults)
| Variable | Default | Description |
|----------|---------|-------------|
| `REGION` | `us-central1` | Deployment region |
| `BACKEND_SERVICE_NAME` | `genai-backend` | Backend Cloud Run service name |
| `FRONTEND_SERVICE_NAME` | `genai-frontend` | Frontend Cloud Run service name |
| `BACKEND_IMAGE_NAME` | `storygen-backend` | Backend Docker image name |
| `FRONTEND_IMAGE_NAME` | `storygen-frontend` | Frontend Docker image name |
| `ARTIFACT_REPO` | `storygen-repo` | Artifact Registry repository |
| `BUCKET_NAME` | `{PROJECT_ID}-story-images` | Cloud Storage bucket |
| `SECRET_NAME` | `storygen-google-api-key` | Secret Manager secret name |
| `BACKEND_MEMORY` | `2Gi` | Backend memory allocation |
| `BACKEND_CPU` | `2` | Backend CPU allocation |
| `FRONTEND_MEMORY` | `1Gi` | Frontend memory allocation |
| `FRONTEND_CPU` | `1` | Frontend CPU allocation |
| `MIN_INSTANCES` | `0` | Minimum service instances |
| `MAX_INSTANCES` | `2` | Maximum service instances |

## 🔧 Deployment Methods

### Method 1: CI/CD Deployment (Recommended)

**Prerequisites:**
- Google Cloud project with billing enabled
- GitHub repository (your fork)
- Workload Identity Provider setup

**Steps:**

1. **Set GitHub Repository Variables:**
   Go to GitHub → Settings → Secrets and variables → Actions → Variables
   
   | Variable Name | Value |
   |---------------|-------|
   | `GCP_PROJECT_ID` | Your project ID (e.g., `sdlcv1`) |
   | `GCP_REGION` | Your region (e.g., `us-central1`) |
   | `BACKEND_SERVICE_NAME` | Backend service name (optional) |
   | `FRONTEND_SERVICE_NAME` | Frontend service name (optional) |

2. **Set GitHub Repository Secrets:**
   Go to GitHub → Settings → Secrets and variables → Actions → Secrets
   
   | Secret Name | Value |
   |-------------|-------|
   | `WORKLOAD_IDENTITY_PROVIDER` | Your workload identity provider URL |
   | `GCP_SERVICE_ACCOUNT_EMAIL` | Your service account email |
   | `GOOGLE_API_KEY` | Your Google AI Studio API key |

3. **Push to main branch** - CI/CD will automatically deploy

### Method 2: Manual Deployment

**Prerequisites:**
- Google Cloud project with billing enabled
- `gcloud` CLI installed and authenticated
- Google AI Studio API key

**Steps:**

1. **Configure environment:**
   ```bash
   # Edit config.env with your project settings
   vim config.env
   ```

2. **Deploy:**
   ```bash
   # Complete deployment (recommended)
   ./deploy-complete.sh

   # Or step-by-step:
   ./setup-secret.sh          # Setup API key
   ./setup-artifact-registry.sh  # Setup Docker registry
   ./deploy-infrastructure.sh    # Deploy with Terraform
   ./deploy-backend.sh          # Deploy backend
   ./deploy-frontend.sh         # Deploy frontend
   ```

## 🏗️ Architecture

The portable deployment creates:

```
┌─────────────────┐
│ Your Project    │
│ (e.g., sdlcv1)  │
├─────────────────┤
│ 🔧 Services     │
│ ├── Backend     │
│ ├── Frontend    │
│ ├── Storage     │
│ └── Secrets     │
│                 │
│ 📦 Resources    │
│ ├── Cloud Run   │
│ ├── Artifact    │
│ │   Registry     │
│ ├── Cloud       │
│ │   Storage     │
│ └── Secret      │
│     Manager     │
└─────────────────┘
```

## 🔄 Multi-Environment Setup

You can easily deploy to multiple environments:

### Development Environment
```bash
# config-dev.env
PROJECT_ID=myproject-dev
BACKEND_SERVICE_NAME=storygen-backend-dev
FRONTEND_SERVICE_NAME=storygen-frontend-dev
```

### Production Environment
```bash
# config-prod.env
PROJECT_ID=myproject-prod
BACKEND_SERVICE_NAME=storygen-backend-prod
FRONTEND_SERVICE_NAME=storygen-frontend-prod
BACKEND_MEMORY=4Gi
BACKEND_CPU=4
```

### Switching Environments
```bash
# Deploy to dev
cp config-dev.env config.env
./deploy-complete.sh

# Deploy to prod
cp config-prod.env config.env
./deploy-complete.sh
```

## 🔍 Validation

### Check Your Configuration
```bash
# Validate your setup
./validate-cicd-setup.sh

# Check deployment status
source config.env
gcloud run services list --project=$PROJECT_ID --region=$REGION
```

### Test Deployment
```bash
# Get service URLs
source config.env
BACKEND_URL=$(gcloud run services describe $BACKEND_SERVICE_NAME \
  --region=$REGION --format="value(status.url)" --project=$PROJECT_ID)
FRONTEND_URL=$(gcloud run services describe $FRONTEND_SERVICE_NAME \
  --region=$REGION --format="value(status.url)" --project=$PROJECT_ID)

# Test backend
curl $BACKEND_URL/health

# Test frontend
curl -I $FRONTEND_URL
```

## 🚨 Troubleshooting

### Common Issues

**1. "Project not found" error**
- Verify `PROJECT_ID` in `config.env` is correct
- Ensure you have access to the project
- Check billing is enabled

**2. "Permission denied" error**
- Verify `gcloud auth login` is done
- Check service account has required permissions
- Ensure Workload Identity is set up correctly

**3. "Billing not enabled" error**
- Enable billing in Google Cloud Console
- Verify billing account is active

### Debug Commands

```bash
# Check current configuration
source config.env
echo "Project: $PROJECT_ID"
echo "Region: $REGION"

# Check authentication
gcloud auth list
gcloud config get-value project

# Check billing
gcloud billing projects describe $PROJECT_ID

# Check services
gcloud run services list --project=$PROJECT_ID --region=$REGION
```

## 📚 File Structure

After setup, your repository will have:

```
storygen-main/
├── config.env                    # ✅ Your project configuration
├── config.example.env           # 📋 Template for new setups
├── terraform_code/
│   ├── input.tfvars             # ✅ Your Terraform variables
│   └── input.tfvars.example     # 📋 Template for new setups
├── .github/workflows/
│   └── ci-cd.yml                # ✅ Configurable CI/CD pipeline
├── setup-new-project.sh         # 🚀 Automated setup script
├── deploy-complete.sh           # 🚀 Complete deployment script
└── PORTABLE_DEPLOYMENT.md       # 📖 This guide
```

## 🎉 Benefits

✅ **No Hardcoded Values**: All project-specific values are configurable
✅ **Fork-Friendly**: New users can deploy by setting variables only
✅ **Multi-Environment**: Easy to deploy to dev/staging/prod
✅ **CI/CD Ready**: GitHub Actions use repository variables
✅ **Manual Friendly**: Scripts use environment files
✅ **Validated**: Built-in checks for configuration and setup

## 📋 Quick Reference

### For New Project Setup
```bash
./setup-new-project.sh
```

### For CI/CD Deployment
1. Set GitHub repository variables and secrets
2. Push to main branch

### For Manual Deployment
```bash
# Edit config.env with your settings
./deploy-complete.sh
```

### For Validation
```bash
./validate-cicd-setup.sh
```

**🚀 Your StoryGen deployment is now fully portable and ready for any Google Cloud project!**
