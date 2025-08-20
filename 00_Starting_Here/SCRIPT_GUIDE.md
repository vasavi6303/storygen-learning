# 🚀 StoryGen Setup Scripts Guide

This directory contains automated setup scripts that can load configuration from your `.env` file for zero-prompt operation.

## 📁 Available Scripts

| Script | Purpose | .env Support | Prompts |
|--------|---------|--------------|---------|
| `setup-direct.sh` | Complete infrastructure setup | ✅ Full | None if .env exists |
| `setup-api-key.sh` | Secret Manager + CI/CD workflow | ✅ Full | None if .env exists |
| `setup-secret-only.sh` | Secret Manager only | ✅ Full | None if .env exists |
| `setup-cicd-only.sh` | CI/CD workflow only | ✅ Full | None if .env exists |
| `test-env-loading.sh` | Test .env configuration | ✅ Full | None |

## 🔧 .env File Configuration

Create a `.env` file in the parent directory (`../`) with these variables:

```env
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY=your-actual-api-key-here
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GENMEDIA_BUCKET=your-bucket-name
GITHUB_USERNAME=your-github-username
GITHUB_REPO=your-repo-name
SECRET_MANAGER=your-secret-name
```

## 🎯 Usage Scenarios

### Scenario 1: Complete Setup (Recommended)
```bash
# Test your .env file first
./test-env-loading.sh

# Set up infrastructure (Workload Identity, Service Account, Bucket, Secret Manager)
./setup-direct.sh

# Add API key to Secret Manager and create CI/CD workflow
./setup-api-key.sh
```

### Scenario 2: Modular Setup
```bash
# Step 1: Infrastructure only
./setup-direct.sh

# Step 2: Secret Manager only (no CI/CD)
./setup-secret-only.sh

# Step 3: CI/CD workflow only (separate)
./setup-cicd-only.sh
```

### Scenario 3: Override Specific Values
```bash
# Use .env for most values, but override project ID
./setup-direct.sh my-different-project

# Use .env for project, but override secret name
./setup-api-key.sh sdlcv2 my-custom-secret
```

## 🔍 Priority Order

Each script follows this priority order:
1. **Command line arguments** (highest priority)
2. **Values from .env file** (automatic loading)
3. **Interactive prompts** (fallback if no .env)

## ✅ What Each Script Does

### `setup-direct.sh`
- ✅ Enables Google Cloud APIs
- ✅ Creates Workload Identity Pool & Provider
- ✅ Creates Service Account with IAM roles
- ✅ Creates Cloud Storage bucket
- ✅ Creates Secret Manager secret (empty)
- ✅ Configures GitHub repository access

### `setup-api-key.sh`
- ✅ Stores API key in Secret Manager
- ✅ Creates personalized GitHub Actions workflow
- ✅ Configures CI/CD pipeline with your project settings

### `setup-secret-only.sh`
- ✅ Stores API key in Secret Manager
- ❌ No CI/CD workflow creation
- ✅ Perfect for manual deployment scenarios

### `setup-cicd-only.sh`
- ❌ No Secret Manager operations
- ✅ Creates GitHub Actions workflow only
- ✅ Assumes Secret Manager is already configured

## 🧪 Testing

Run the test script first to verify your .env configuration:

```bash
./test-env-loading.sh
```

This will show you:
- Which variables are loaded from .env
- Which scripts will work without prompts
- Any missing configuration

## 🎉 Benefits

**With .env file:**
- ⚡ Zero prompts - fully automated
- 🔒 Secure API key handling
- 🔄 Consistent configuration across runs
- 🎯 Easy to share configuration (without exposing secrets)

**Fallback behavior:**
- 📝 Interactive prompts if .env missing
- 🔧 Override specific values via command line
- 🛡️ Validation and error checking

## 🚨 Security Notes

- Keep your `.env` file secure and never commit it to git
- The scripts will show first 10 characters of API key for verification
- All sensitive data is handled securely through Google Cloud Secret Manager

## 📋 Next Steps After Setup

1. **Push to GitHub main branch** - triggers automatic deployment
2. **Monitor in GitHub Actions** - watch the CI/CD pipeline
3. **Access deployed application** - URLs shown in workflow output

Happy deploying! 🚀
