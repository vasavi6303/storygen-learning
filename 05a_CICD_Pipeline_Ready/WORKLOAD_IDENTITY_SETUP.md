# 🔐 Workload Identity Setup for StoryGen CI/CD

This guide provides automated scripts to configure GitHub Actions authentication with Google Cloud Platform using Workload Identity Federation.

## 🚀 Quick Setup (5 Minutes)

### Option 1: Automated Setup Script (Recommended)

Run the automated setup script that configures everything for you:

```bash
./setup-workload-identity.sh
```

This script will:
- ✅ Check prerequisites (gcloud CLI, authentication)
- ✅ Prompt for your configuration (project ID, GitHub repo, etc.)
- ✅ Enable required Google Cloud APIs
- ✅ Create Workload Identity Pool and Provider
- ✅ Create service account with proper permissions
- ✅ Configure GitHub repository access
- ✅ Generate the exact secrets and variables you need for GitHub

### Option 2: Manual Setup

Follow the detailed manual steps in [FORK_SETUP.md](./FORK_SETUP.md).

## 📋 Prerequisites

Before running the setup script, ensure you have:

- ✅ **Google Cloud Project** with billing enabled
- ✅ **gcloud CLI** installed and authenticated (`gcloud auth login`)
- ✅ **Project access** (Owner or Editor role recommended)
- ✅ **GitHub repository** (your fork of StoryGen)

### Install gcloud CLI

If you don't have gcloud CLI installed:

```bash
# macOS
brew install google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

Authenticate with gcloud:
```bash
gcloud auth login
gcloud auth application-default login
```

## 🔧 Usage

### 1. Run the Setup Script

```bash
# Make sure you're in the project directory
cd storygen-main

# Run the setup script
./setup-workload-identity.sh
```

The script will prompt you for:
- **Google Cloud Project ID**
- **Deployment Region** (default: us-central1)
- **GitHub Username**
- **Repository Name** (default: storygen-main)

### 2. Copy GitHub Configuration

The script will output the exact secrets and variables you need to add to GitHub:

#### GitHub Repository Secrets
Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`

- `WORKLOAD_IDENTITY_PROVIDER`: Generated automatically
- `GCP_SERVICE_ACCOUNT_EMAIL`: Generated automatically  
- `GOOGLE_API_KEY`: Get from [Google AI Studio](https://aistudio.google.com/)

#### GitHub Repository Variables
Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/variables/actions`

- `GCP_PROJECT_ID`: Your project ID
- `GCP_REGION`: Your chosen region
- `ARTIFACT_REPO`: storygen-repo
- `BACKEND_SERVICE_NAME`: genai-backend
- `FRONTEND_SERVICE_NAME`: genai-frontend

### 3. Get Google AI API Key

1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Create or select a project
3. Generate an API key
4. Add it as `GOOGLE_API_KEY` secret in GitHub

### 4. Test the Setup

Validate your configuration:

```bash
./validate-workload-identity.sh
```

This script will:
- ✅ Check that all components are configured correctly
- ✅ Verify service account permissions
- ✅ Test Workload Identity bindings
- ✅ Generate the GitHub configuration values again

### 5. Trigger CI/CD

Once everything is configured:

1. **Push to main branch** or **manually trigger** the workflow
2. **Monitor GitHub Actions** for successful deployment
3. **Access your deployed app** (URLs provided in workflow output)

## 🔍 Verification

### Check Configuration Locally

```bash
# List Workload Identity pools
gcloud iam workload-identity-pools list --location=global --project=YOUR_PROJECT_ID

# Check service account
gcloud iam service-accounts list --project=YOUR_PROJECT_ID

# Verify permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID
```

### Test GitHub Actions Authentication

The best test is to trigger your CI/CD workflow and check that it passes the "Setup Infrastructure" stage without authentication errors.

## 🛠️ Customization

### Using Different Names

You can customize the component names when running the setup script:

- **Service Account Name**: Default is `github-actions`
- **Workload Identity Pool**: Default is `github-pool`
- **Provider Name**: Default is `github-provider`

### Multiple Repositories

To use the same Workload Identity setup for multiple repositories, run:

```bash
# For each additional repository
gcloud iam service-accounts add-iam-policy-binding \
  github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project="YOUR_PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_USERNAME/REPO_NAME"
```

## 🚨 Troubleshooting

### Common Issues

#### Script Fails with "Project not accessible"
```bash
# Check authentication
gcloud auth list

# Set project
gcloud config set project YOUR_PROJECT_ID

# Check billing
gcloud billing projects describe YOUR_PROJECT_ID
```

#### "API not enabled" errors
```bash
# Enable APIs manually
gcloud services enable iamcredentials.googleapis.com iam.googleapis.com --project=YOUR_PROJECT_ID
```

#### CI/CD still fails after setup
1. **Double-check GitHub secrets and variables** are set exactly as provided
2. **Verify repository name** matches exactly (case-sensitive)
3. **Check GitHub Actions logs** for specific error messages
4. **Run validation script** to verify setup

### Getting Help

1. **Run the validation script**: `./validate-workload-identity.sh`
2. **Check setup summary**: Look for `workload-identity-setup-summary.txt` file
3. **Review GitHub Actions logs** for detailed error messages
4. **Verify billing** is enabled for your Google Cloud project

## 📁 Files Created

The setup script creates:

- `workload-identity-setup-summary.txt` - Complete configuration summary
- Workload Identity Pool and Provider in Google Cloud
- Service account with required permissions
- IAM bindings for GitHub repository access

## 🎯 What This Solves

This setup eliminates the CI/CD error:
```
❌ WORKLOAD_IDENTITY_PROVIDER secret not set
Please set up Workload Identity Provider and add it to repository secrets
```

After running the setup script and configuring GitHub, your CI/CD pipeline will:
- ✅ Authenticate securely with Google Cloud
- ✅ Deploy infrastructure automatically
- ✅ Build and deploy both backend and frontend
- ✅ Provide working service URLs

## 🔗 Related Documentation

- [FORK_SETUP.md](./FORK_SETUP.md) - Complete fork setup guide
- [CI_CD_README.md](./CI_CD_README.md) - CI/CD pipeline documentation
- [Google Cloud Workload Identity](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

**Ready to set up Workload Identity?** Run `./setup-workload-identity.sh` to get started! 🚀
