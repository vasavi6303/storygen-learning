# StoryGen New Deployment Guide

## Overview

This is the **improved, beginner-friendly deployment strategy** that builds Docker images first, then deploys infrastructure with Terraform using those real images.

## Why This Approach?

✅ **Reliable**: Docker images are built and tested before infrastructure deployment  
✅ **Portable**: Works for any user with just a `.env` file  
✅ **Clear**: Step-by-step process that's easy to understand  
✅ **Production-ready**: Uses real images, not placeholders  

## Quick Start (For New Users)

### 1. Setup Your Environment

```bash
# Copy the environment template
cp ../env.template ../.env

# Edit with your values
nano ../.env
```

**Required variables in `.env`:**
```bash
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY=your_google_api_key
GOOGLE_CLOUD_PROJECT_ID=your_project_id
GENMEDIA_BUCKET=your_bucket_name
SECRET_MANAGER=your_secret_name
```

### 2. One-Command Deployment

```bash
cd 04b_Manual_Deployment_Done
./deploy-all.sh
```

That's it! The script will:
- Set up prerequisites (APIs, Artifact Registry, secrets)
- Build and push Docker images
- Deploy infrastructure with Terraform
- Give you working URLs

### 3. Access Your Application

After deployment, you'll get URLs like:
- **Frontend**: `https://genai-frontend-xxx-uc.a.run.app`
- **Backend**: `https://genai-backend-xxx-uc.a.run.app`

## Step-by-Step Deployment

## Individual Steps (Recommended for New Users)

For better control and understanding, run individual steps:

```bash
# Step 1: Prerequisites (APIs, Artifact Registry, Secrets)
./01-setup.sh

# Step 2: Build and push Docker images
./02-build-images.sh

# Step 3: Deploy infrastructure with Terraform
./03-deploy-infrastructure.sh
```

This approach gives you:
- ✅ **Visibility**: See each step complete successfully
- ✅ **Control**: Stop and fix issues at any step
- ✅ **Learning**: Understand what each script does
- ✅ **Debugging**: Easier to troubleshoot specific steps

## How It Works

### Step 1: Prerequisites (`01-setup.sh`)
- Enables required Google Cloud APIs
- Creates Artifact Registry repository
- Sets up Secret Manager with your API key
- Configures Docker authentication

### Step 2: Build Images (`02-build-images.sh`)
- Builds backend Docker image with Cloud Build
- Builds frontend Docker image with Cloud Build
- Pushes images to Artifact Registry
- Creates `terraform_code/images.tfvars` with image references
- Tags images with timestamps and `:latest`

### Step 3: Deploy Infrastructure (`03-deploy-infrastructure.sh`)
- Loads environment variables from `.env`
- Creates Terraform variables from environment
- Uses real Docker images (not placeholders)
- Deploys Cloud Run services, buckets, IAM roles
- Saves deployment URLs for easy access

## File Structure

```
04b_Manual_Deployment_Done/
├── deploy-all.sh                 # One-command deployment
├── 01-setup.sh                   # Prerequisites setup
├── 02-build-images.sh            # Docker image building
├── 03-deploy-infrastructure.sh   # Terraform deployment
├── load-env.sh                   # Environment loader
├── terraform_code/
│   ├── main.tf                   # Parameterized infrastructure
│   ├── variables.tf              # Variable definitions
│   ├── input.tfvars             # Generated from .env
│   └── images.tfvars            # Generated image references
├── backend/
│   └── Dockerfile              # Backend container
└── frontend/
    └── Dockerfile              # Frontend container
```

## For Existing Users

If you were using the old deployment process, the new approach is much cleaner:

**Old way:**
```bash
./setup-prerequisites.sh
./deploy-terraform.sh           # ❌ Could fail with placeholder images
./deploy-backend-new.sh         # 🔄 Separate image building
./deploy-frontend-new.sh        # 🔄 Separate image building
```

**New way:**
```bash
./deploy-all.sh                 # ✅ Everything in correct order
```

## Customization

### Different Image Tags

To use specific image versions:
```bash
# Build with custom tags
TIMESTAMP=v1.0.0 ./02-build-images.sh

# Or edit terraform_code/images.tfvars manually
```

### Resource Configuration

Edit your `.env` file:
```bash
BACKEND_MEMORY=4Gi
BACKEND_CPU=4
MAX_INSTANCES=5
```

### Additional Terraform Resources

Add to `terraform_code/main.tf` for custom infrastructure needs.

## Troubleshooting

### Authentication Issues
```bash
gcloud auth login
gcloud auth application-default login
```

### Billing Issues
Ensure your project has an active billing account in the Google Cloud Console.

### Build Failures
Check Cloud Build logs:
```bash
gcloud builds list --project=YOUR_PROJECT_ID
```

### View Application Logs
```bash
gcloud logs tail --filter="resource.type=cloud_run_revision" --project=YOUR_PROJECT_ID
```

### Cleanup
```bash
cd terraform_code
terraform destroy -var-file=input.tfvars -var-file=images.tfvars
```

## Benefits of This Approach

1. **No Placeholder Images**: Terraform deploys with real, working containers
2. **Versioned Images**: Each deployment creates timestamped images
3. **Environment Driven**: All configuration comes from `.env`
4. **Beginner Friendly**: One script does everything
5. **Portable**: Works for any user/project
6. **Production Ready**: Built for real-world deployments

This deployment strategy ensures reliability and makes it easy for anyone to deploy StoryGen to their own Google Cloud project!
