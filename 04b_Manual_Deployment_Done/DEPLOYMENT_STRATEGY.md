# StoryGen Deployment Strategy

This directory contains a complete, parameterized deployment solution for the StoryGen application that works with any Google Cloud project.

## Overview

The deployment strategy follows these key principles:

1. **Environment-driven configuration**: All project-specific values are loaded from a `.env` file
2. **Modular deployment**: Separate scripts for infrastructure, backend, and frontend
3. **Portable**: Works for any user who forks the repo with minimal setup
4. **Terraform-managed infrastructure**: All GCP resources defined as code
5. **Docker-based deployment**: Both backend and frontend are containerized

## File Structure

```
04b_Manual_Deployment_Done/
├── deploy-complete-new.sh        # Master deployment orchestration script
├── setup-prerequisites.sh       # Sets up GCP APIs, Artifact Registry, and secrets
├── deploy-terraform.sh          # Deploys infrastructure using Terraform
├── deploy-backend-new.sh         # Builds and deploys backend service
├── deploy-frontend-new.sh        # Builds and deploys frontend service
├── load-env.sh                   # Loads and validates environment variables
├── backend/
│   ├── Dockerfile               # Backend container definition
│   └── ... (application code)
├── frontend/
│   ├── Dockerfile               # Frontend container definition (Next.js)
│   └── ... (application code)
└── terraform_code/
    ├── main.tf                  # Parameterized infrastructure definition
    ├── variables.tf             # Terraform variable definitions
    ├── outputs.tf               # Infrastructure outputs
    └── providers.tf             # Terraform provider configuration
```

## Quick Start

### 1. Setup Environment

Create a `.env` file in the project root with your configuration:

```bash
# Copy the template
cp env.template .env

# Edit with your values
nano .env
```

Required variables:
- `GOOGLE_CLOUD_PROJECT_ID`: Your GCP project ID
- `GOOGLE_API_KEY`: Google AI Studio API key
- `GENMEDIA_BUCKET`: Cloud Storage bucket name for images
- `SECRET_MANAGER`: Secret Manager secret name

### 2. Deploy Everything

```bash
cd 04b_Manual_Deployment_Done
./deploy-complete-new.sh
```

This single command will:
1. Set up GCP prerequisites (APIs, Artifact Registry, secrets)
2. Deploy infrastructure with Terraform
3. Build and deploy the backend service
4. Build and deploy the frontend service

### 3. Access Your Application

After deployment, you'll get URLs for both services:
- Frontend: `https://your-frontend-service-url`
- Backend: `https://your-backend-service-url`

## Individual Deployment Commands

You can also run individual deployment steps:

```bash
# Step 1: Prerequisites (APIs, Artifact Registry, Secrets)
./01-setup.sh

# Step 2: Build and push Docker images
./02-build-images.sh

# Step 3: Deploy infrastructure with Terraform
./03-deploy-infrastructure.sh
```

## Configuration Details

### Environment Variables

The `.env` file supports the following variables:

#### Required
- `GOOGLE_GENAI_USE_VERTEXAI`: Set to FALSE for Google AI Studio
- `GOOGLE_API_KEY`: Your Google AI Studio API key
- `GOOGLE_CLOUD_PROJECT_ID`: Your GCP project ID
- `GENMEDIA_BUCKET`: Cloud Storage bucket name
- `SECRET_MANAGER`: Secret Manager secret name

#### Optional (with defaults)
- `REGION`: Deployment region (default: us-central1)
- `BACKEND_SERVICE_NAME`: Backend Cloud Run service name
- `FRONTEND_SERVICE_NAME`: Frontend Cloud Run service name
- `BACKEND_IMAGE_NAME`: Backend Docker image name
- `FRONTEND_IMAGE_NAME`: Frontend Docker image name
- `ARTIFACT_REPO`: Artifact Registry repository name
- `BACKEND_MEMORY`: Backend memory allocation (default: 2Gi)
- `BACKEND_CPU`: Backend CPU allocation (default: 2)
- `FRONTEND_MEMORY`: Frontend memory allocation (default: 1Gi)
- `FRONTEND_CPU`: Frontend CPU allocation (default: 1)
- `MIN_INSTANCES`: Minimum instances (default: 0)
- `MAX_INSTANCES`: Maximum instances (default: 2)

### Terraform Infrastructure

The Terraform configuration creates:

- **Cloud Run services**: Backend and frontend services
- **Cloud Storage bucket**: For storing generated images
- **Secret Manager**: For storing API keys securely
- **Artifact Registry**: For storing Docker images
- **IAM roles**: Proper permissions for services
- **APIs**: Required Google Cloud APIs

### Docker Images

#### Backend
- Based on Python 3.10
- Uses Gunicorn with Uvicorn workers for WebSocket support
- Includes all Python dependencies
- Configured for Cloud Run port 8080

#### Frontend
- Based on Node.js 18 Alpine
- Uses pnpm for package management
- Next.js production build
- Configured for Cloud Run port 3000

## For New Users

If you're forking this repo for a new project:

1. **Clone the repository**
2. **Create your .env file** from the template
3. **Update project-specific values**:
   - `GOOGLE_CLOUD_PROJECT_ID`: Your GCP project
   - `GENMEDIA_BUCKET`: Your bucket name
   - `SECRET_MANAGER`: Your secret name
4. **Run the deployment**: `./deploy-complete-new.sh`

No hardcoded values need to be changed in the code!

## Troubleshooting

### Authentication Issues
```bash
gcloud auth login
gcloud auth application-default login
```

### Missing APIs
The setup script automatically enables required APIs, but if you see API errors:
```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
```

### Permission Issues
Ensure your user has the following roles:
- Cloud Run Admin
- Artifact Registry Admin
- Secret Manager Admin
- Storage Admin
- Service Usage Admin

### View Logs
```bash
gcloud logs tail --filter="resource.type=cloud_run_revision" --project=YOUR_PROJECT_ID
```

## Cleanup

To remove all deployed resources:

```bash
cd terraform_code
terraform destroy -var-file=input.tfvars
```

This will remove all infrastructure except the Artifact Registry repository and Secret Manager secrets, which need to be deleted manually if desired.

## Customization

The deployment is designed to be easily customizable:

- **Resource allocation**: Modify CPU/memory in `.env`
- **Scaling**: Adjust min/max instances in `.env`
- **Regions**: Change deployment region in `.env`
- **Service names**: Customize service names in `.env`
- **Additional infrastructure**: Modify `terraform_code/main.tf`
- **Build configuration**: Modify Dockerfiles as needed

This deployment strategy provides a robust, portable foundation for deploying the StoryGen application to any Google Cloud environment.
