# StoryGen Individual Script Deployment

This guide shows how to deploy StoryGen using individual scripts for maximum control and visibility.

## Quick Start for New Users

### 1. Setup Your Environment

```bash
# Copy the environment template
cp ../env.template ../.env

# Edit with your values
nano ../.env
```

**Required variables:**
```bash
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY=your_google_api_key
GOOGLE_CLOUD_PROJECT_ID=your_project_id
GENMEDIA_BUCKET=your_bucket_name
SECRET_MANAGER=your_secret_name
```

### 2. Run Individual Scripts

```bash
# Step 1: Prerequisites Setup
./01-setup.sh
# ✅ Enables APIs, creates Artifact Registry, sets up secrets

# Step 2: Build Docker Images  
./02-build-images.sh
# ✅ Builds backend and frontend images, pushes to registry

# Step 3: Deploy Infrastructure
./03-deploy-infrastructure.sh
# ✅ Deploys Cloud Run services with Terraform
```

### 3. Get Your URLs

After step 3, you'll see:
```
🌐 Frontend: https://genai-frontend-xxx-uc.a.run.app
🔗 Backend:  https://genai-backend-xxx-uc.a.run.app
```

## What Each Script Does

### `01-setup.sh`
- ✅ Enables required Google Cloud APIs
- ✅ Creates Artifact Registry repository
- ✅ Sets up Secret Manager with your API key
- ✅ Configures Docker authentication

### `02-build-images.sh`
- ✅ Builds backend Docker image with Cloud Build
- ✅ Builds frontend Docker image with Cloud Build
- ✅ Pushes images to Artifact Registry with version tags
- ✅ Creates `terraform_code/images.tfvars` with image references

### `03-deploy-infrastructure.sh`
- ✅ Loads environment variables from `.env`
- ✅ Creates Terraform variables from environment
- ✅ Imports existing resources (like storage bucket) to avoid conflicts
- ✅ Deploys Cloud Run services using real Docker images
- ✅ Outputs working application URLs

## Benefits of Individual Scripts

### ✅ **Visibility**
See exactly what each step does and when it completes

### ✅ **Control** 
Stop at any step to fix issues or make changes

### ✅ **Debugging**
Easier to identify and fix problems at specific steps

### ✅ **Learning**
Understand the deployment process step by step

### ✅ **Reusability**
Re-run specific steps (like rebuilding images) without full redeployment

## Common Workflows

### First-time Deployment
```bash
./01-setup.sh          # One-time setup
./02-build-images.sh   # Build images
./03-deploy-infrastructure.sh  # Deploy
```

### Update Application Code
```bash
./02-build-images.sh   # Rebuild with new code
./03-deploy-infrastructure.sh  # Deploy updated images
```

### Infrastructure Changes Only
```bash
./03-deploy-infrastructure.sh  # Apply Terraform changes
```

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform installed
- Docker (optional - Cloud Build is used)
- Project with billing enabled

## Troubleshooting

### Authentication Issues
```bash
gcloud auth login
gcloud auth application-default login
```

### Build Failures
Check Cloud Build logs:
```bash
gcloud builds list --project=YOUR_PROJECT_ID
```

### Deployment Issues
Check Cloud Run logs:
```bash
gcloud logs tail --filter="resource.type=cloud_run_revision" --project=YOUR_PROJECT_ID
```

### Validation
Test the scripts before running:
```bash
./test-individual-scripts.sh
```

This approach ensures reliable, reproducible deployments for any user!
