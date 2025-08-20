# 🚀 StoryGen Quick Start Guide

**Complete CI/CD setup in 3 simple steps!**

This guide will get your StoryGen application deployed to Google Cloud with automatic CI/CD in just a few minutes.

## 📋 Prerequisites

Before you start, make sure you have:

1. **Google Cloud Project** with billing enabled
2. **Google Cloud CLI** installed and authenticated
3. **GitHub repository** (your fork of StoryGen)
4. **Owner/Editor permissions** on your Google Cloud project

### Install Google Cloud CLI (if needed):
```bash
# macOS
brew install google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

### Authenticate with Google Cloud:
```bash
gcloud auth login
gcloud auth application-default login
```

## 🎯 Step-by-Step Setup

### **Step 1: Configure Google Cloud Resources**

Run the setup script to create all required Google Cloud resources:

```bash
./setup-direct.sh YOUR_PROJECT_ID YOUR_GITHUB_USERNAME YOUR_REPO_NAME
```

**Example:**
```bash
./setup-direct.sh my-storygen-project myusername storygen-main
```

**What this creates:**
- ✅ Workload Identity Pool & Provider (secure GitHub→GCP authentication)
- ✅ Service Account with comprehensive permissions
- ✅ Cloud Storage bucket for generated images
- ✅ Secret Manager for secure API key storage
- ✅ All required Google Cloud APIs enabled

### **Step 2: Add Your Gemini API Key**

Get your API key from [Google AI Studio](https://aistudio.google.com/) and run:

```bash
./setup-api-key.sh
```

The script will:
- ✅ Securely store your API key in Secret Manager
- ✅ **Automatically customize the CI/CD workflow** for your project
- ✅ Remove duplicate workflows (keeps only one active)
- ✅ Set up everything for automatic deployment

### **Step 3: Deploy!**

Push your code to the main branch:

```bash
git add .
git commit -m "Initial setup complete"
git push origin main
```

**That's it!** 🎉

## 📊 What Happens Next

1. **GitHub Actions automatically triggers** when you push to main
2. **Infrastructure is verified** and APIs are enabled
3. **Backend and frontend are built** using Cloud Build
4. **Services are deployed** to Cloud Run
5. **Health checks verify** everything is working
6. **URLs are provided** in the workflow output

## 🔍 Monitoring Your Deployment

### View Deployment Progress:
1. Go to your GitHub repository
2. Click the **"Actions"** tab
3. Watch the **"StoryGen CI/CD"** workflow

### Access Your Deployed App:
The workflow output will show your service URLs:
```
🎉 Deployment Complete!
🔗 Backend:  https://genai-backend-PROJECT_ID.us-central1.run.app
🌐 Frontend: https://genai-frontend-PROJECT_ID.us-central1.run.app
```

## 🛠️ Troubleshooting

### Common Issues:

#### ❌ "Project not accessible"
**Solution:** Check your project ID and ensure you have owner/editor permissions.

#### ❌ "API key seems too short"
**Solution:** Get a valid API key from https://aistudio.google.com/

#### ❌ "gcloud CLI not found"
**Solution:** Install Google Cloud CLI: https://cloud.google.com/sdk/docs/install

#### ❌ "Not authenticated with gcloud"
**Solution:** Run `gcloud auth login`

### Getting Help:

1. **Check GitHub Actions logs** for detailed error messages
2. **Run validation script**: `./validate-workload-identity.sh`
3. **Check Cloud Run logs**: 
   ```bash
   gcloud run services logs read genai-backend --region=us-central1 --project=YOUR_PROJECT_ID
   ```

## 🔧 Advanced Configuration

### Update Your API Key:
```bash
./setup-api-key.sh
```

### Change Deployment Region:
Add this GitHub repository variable:
- **Name**: `GCP_REGION`  
- **Value**: `europe-west1` (or your preferred region)

### Custom Service Names:
Add these GitHub repository variables:
- `BACKEND_SERVICE_NAME`: Custom backend name
- `FRONTEND_SERVICE_NAME`: Custom frontend name

### View Secret Manager:
```bash
gcloud secrets list --project=YOUR_PROJECT_ID
gcloud secrets versions access latest --secret=storygen-google-api-key --project=YOUR_PROJECT_ID
```

## 📋 What's Different About This Setup

### **✅ No GitHub Secrets Required!**
Unlike traditional setups, this approach:
- **Hardcodes authentication values** in the workflow (secure and simple)
- **Uses Secret Manager** for sensitive data (API keys)
- **Requires minimal GitHub configuration**

### **🔄 Automatic Workflow Customization**
The `setup-api-key.sh` script automatically:
- **Backs up any existing workflows** to `.github/workflows/backup/`
- **Creates a personalized `ci-cd.yml`** with YOUR project values:
  - Your project ID
  - Your Workload Identity Provider URL
  - Your service account email
  - Your bucket and secret names
- **Keeps only one active workflow** to prevent conflicts
- **No manual editing required!**

### **🚀 Automatic Everything**
After setup:
- **Every push to main** triggers deployment
- **No manual intervention** required
- **Health checks** ensure everything works
- **URLs are automatically generated**

## 🎉 Success Indicators

Your setup is working correctly when:

1. **Setup scripts complete** without errors
2. **GitHub Actions workflow runs** successfully
3. **Both services deploy** to Cloud Run
4. **Health checks pass**
5. **Frontend connects** to backend
6. **Story generation works** end-to-end

## 🔗 Additional Resources

- **Setup Scripts Documentation**: Check the comments in `setup-direct.sh` and `setup-api-key.sh`
- **Workflow Details**: See `.github/workflows/ci-cd.yml`
- **Manual Deployment**: Check `DEPLOYMENT.md` for local deployment options
- **Troubleshooting**: See `validate-workload-identity.sh` for diagnostic tools

---

**Ready to get started?** Run the first setup script and you'll have a fully deployed StoryGen application in minutes! 🚀

```bash
./setup-direct.sh YOUR_PROJECT_ID YOUR_GITHUB_USERNAME YOUR_REPO_NAME
```
