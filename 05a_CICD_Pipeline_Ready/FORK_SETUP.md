# Fork Setup Guide - StoryGen CI/CD

This guide helps you set up the complete CI/CD pipeline for your forked StoryGen repository.

## 🚀 Quick Setup (5 Minutes)

### 1. Fork Prerequisites

Before enabling CI/CD, ensure you have:

- ✅ **Google Cloud Project** with billing enabled
- ✅ **Google AI Studio API Key** from [aistudio.google.com](https://aistudio.google.com/)
- ✅ **GitHub repository** (your fork)
- ✅ **gcloud CLI** installed locally for initial setup

### 2. Google Cloud Setup

#### A. Create Workload Identity Pool

Run these commands locally to set up GitHub authentication:

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"

# Enable required APIs
gcloud services enable iamcredentials.googleapis.com \
  --project=$PROJECT_ID

# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create service account
gcloud iam service-accounts create github-actions \
  --project="$PROJECT_ID" \
  --display-name="GitHub Actions"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Allow GitHub to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USERNAME/storygen-main" \
  github-actions@$PROJECT_ID.iam.gserviceaccount.com

# Get the Workload Identity Provider URL (save this!)
gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

**⚠️ Important**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username in the last command.

#### B. Get Project Number

```bash
# Get your project number (save this!)
gcloud projects describe $PROJECT_ID --format='value(projectNumber)'
```

### 3. GitHub Repository Configuration

#### A. Set Repository Variables

Go to your GitHub repository → Settings → Secrets and variables → Actions → Variables tab:

| Variable Name | Value | Example |
|---------------|-------|---------|
| `GCP_PROJECT_ID` | Your GCP Project ID | `my-storygen-project` |
| `GCP_REGION` | Deployment region | `us-central1` |
| `ARTIFACT_REPO` | Docker repository name | `storygen-repo` |
| `BACKEND_SERVICE_NAME` | Backend service name | `genai-backend` |
| `FRONTEND_SERVICE_NAME` | Frontend service name | `genai-frontend` |
| `BACKEND_IMAGE_NAME` | Backend image name | `storygen-backend` |
| `FRONTEND_IMAGE_NAME` | Frontend image name | `storygen-frontend` |
| `BUCKET_NAME` | Storage bucket name | `genai-story-images` |
| `SECRET_NAME` | Secret Manager secret name | `storygen-google-api-key` |

#### B. Set Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → Secrets tab:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider` | From step 2B above |
| `GCP_SERVICE_ACCOUNT_EMAIL` | `github-actions@PROJECT_ID.iam.gserviceaccount.com` | Replace PROJECT_ID with yours |
| `GOOGLE_API_KEY` | Your Google AI Studio API key | From [aistudio.google.com](https://aistudio.google.com/) |

### 4. Update Terraform Configuration

Create or update `terraform_code/input.tfvars`:

```hcl
# Auto-configured by CI/CD, but you can customize here
project_id = "your-gcp-project-id"
region = "us-central1"
```

### 5. Test the Pipeline

1. **Push to main branch** or **manually trigger** the workflow
2. **Monitor progress** in GitHub Actions tab
3. **Check deployment** - services should be available within 5-10 minutes

## 🔧 Customization Options

### Service Names

If you want different service names, update these repository variables:

```
BACKEND_SERVICE_NAME=my-custom-backend
FRONTEND_SERVICE_NAME=my-custom-frontend
```

### Different Region

```
GCP_REGION=europe-west1
```

### Custom Bucket Name

```
BUCKET_NAME=my-custom-bucket-name
```

## 🏥 Health Checks

The pipeline includes automatic health checks:

- ✅ **Backend Health**: Tests `/health` endpoint
- ✅ **Frontend Accessibility**: Tests main page load
- ✅ **Service URLs**: Outputs working URLs

## 🚨 Troubleshooting

### Common Issues

#### 1. Workload Identity Permission Denied
```
Error: google: could not find default credentials
```

**Solution**: Verify your Workload Identity setup:
1. Check `WORKLOAD_IDENTITY_PROVIDER` secret format
2. Ensure GitHub username is correct in the service account binding
3. Verify service account has required permissions

#### 2. API Not Enabled
```
Error: API [service] not enabled
```

**Solution**: The pipeline auto-enables APIs, but you can manually enable:
```bash
gcloud services enable SERVICE_NAME --project=PROJECT_ID
```

#### 3. Artifact Registry Permission Denied
```
Error: denied: Permission "artifactregistry.repositories.create" denied
```

**Solution**: Ensure service account has `roles/artifactregistry.admin` role.

#### 4. Secret Manager Access Denied
```
Error: failed to access secret version
```

**Solution**: 
1. Check `GOOGLE_API_KEY` secret is set
2. Verify service account has `roles/secretmanager.admin` role

### Debug Commands

Check your setup locally:

```bash
# Test authentication
gcloud auth list

# Check project
gcloud config get-value project

# Test API access
gcloud secrets list --project=PROJECT_ID

# Check service account
gcloud iam service-accounts list --project=PROJECT_ID
```

### Getting Help

1. **Check GitHub Actions logs** for detailed error messages
2. **Check Cloud Build logs** in Google Cloud Console
3. **Check Cloud Run logs** for runtime issues
4. **Verify all secrets and variables** are set correctly

## 🎯 What the Pipeline Does

### Complete Flow
1. **Infrastructure Setup**
   - ✅ Enables required APIs
   - ✅ Creates Artifact Registry
   - ✅ Sets up Secret Manager
   - ✅ Deploys Terraform infrastructure

2. **Backend Deployment**
   - ✅ Builds Docker image with Cloud Build
   - ✅ Pushes to Artifact Registry
   - ✅ Deploys to Cloud Run
   - ✅ Configures environment variables and secrets

3. **Frontend Deployment**
   - ✅ Builds with backend URL
   - ✅ Pushes to Artifact Registry
   - ✅ Deploys to Cloud Run
   - ✅ Configures environment variables

4. **Validation**
   - ✅ Health checks both services
   - ✅ Provides deployment summary
   - ✅ Outputs service URLs

### Result
After successful deployment, you'll have:
- 🚀 **Backend API** running on Cloud Run
- 🌐 **Frontend App** running on Cloud Run  
- 🔒 **Secure** API key storage in Secret Manager
- 📦 **Container images** in Artifact Registry
- ☁️ **Infrastructure** managed by Terraform

## 📋 Repository Structure

Your fork should have this structure for CI/CD to work:

```
your-fork/
├── .github/workflows/ci-cd.yml     ✅ Complete CI/CD pipeline
├── terraform_code/
│   ├── main.tf                     ✅ Infrastructure as code
│   ├── input.tfvars               ✅ Terraform variables
│   └── ...
├── backend/
│   ├── Dockerfile                 ✅ Backend container
│   ├── main.py                    ✅ FastAPI application
│   └── ...
├── frontend/
│   ├── Dockerfile                 ✅ Frontend container
│   ├── package.json               ✅ Next.js application
│   └── ...
└── FORK_SETUP.md                  ✅ This guide
```

---

## 🎉 Success!

Once setup is complete, every push to `main` will automatically:
1. Deploy your complete infrastructure
2. Build and deploy your backend
3. Build and deploy your frontend
4. Validate everything is working

Your StoryGen app will be fully deployed and ready to use! 🚀
