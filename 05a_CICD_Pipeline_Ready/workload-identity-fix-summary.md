# 🔧 Workload Identity Fix Summary

## ❌ **Root Cause of the Error**

The error you received:
```
Permission 'iam.serviceAccounts.getAccessToken' denied on resource
```

This happened because:

1. **Wrong Repository Name**: Your actual repository is `cuppibla/storygeneration`
2. **Permissions were set for**: `cuppibla/storygen-main` and `cuppibla/storygen-1`
3. **Missing Service Account Impersonation**: The Workload Identity Provider couldn't impersonate the `cicd-sa` service account

## ✅ **What I Fixed**

### 1. **Added Service Account Impersonation Permissions**
```bash
# Added for correct repository: cuppibla/storygeneration
gcloud iam service-accounts add-iam-policy-binding cicd-sa@sdlc-468305.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountTokenCreator \
  --member "principalSet://iam.googleapis.com/projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/cuppibla/storygeneration"

gcloud iam service-accounts add-iam-policy-binding cicd-sa@sdlc-468305.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountUser \
  --member "principalSet://iam.googleapis.com/projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/cuppibla/storygeneration"
```

### 2. **Added Project-Level Permissions for Correct Repository**
```bash
# Artifact Registry permissions
gcloud projects add-iam-policy-binding sdlc-468305 \
  --role roles/artifactregistry.writer \
  --member "principalSet://iam.googleapis.com/projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/cuppibla/storygeneration"

# Cloud Run permissions
gcloud projects add-iam-policy-binding sdlc-468305 \
  --role roles/run.admin \
  --member "principalSet://iam.googleapis.com/projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/cuppibla/storygeneration"

# Cloud Build permissions
gcloud projects add-iam-policy-binding sdlc-468305 \
  --role roles/cloudbuild.builds.builder \
  --member "principalSet://iam.googleapis.com/projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/attribute.repository/cuppibla/storygeneration"
```

## 🎯 **Current Working Configuration**

### Repository Information
- **Your Repository**: `cuppibla/storygeneration`
- **Workload Identity Provider**: `projects/453527276826/locations/global/workloadIdentityPools/github-pool-v2/providers/github-provider-v2`
- **Service Account**: `cicd-sa@sdlc-468305.iam.gserviceaccount.com`

### Permissions Added
✅ **Service Account Level**:
- `roles/iam.serviceAccountTokenCreator` - Allows GitHub to get access tokens
- `roles/iam.serviceAccountUser` - Allows GitHub to use the service account

✅ **Project Level**:
- `roles/artifactregistry.writer` - Push Docker images
- `roles/run.admin` - Deploy to Cloud Run
- `roles/cloudbuild.builds.builder` - Build Docker images
- `roles/editor` - General project access (via cicd-sa)

## 🚀 **What Should Work Now**

Your CI/CD pipeline should now be able to:

1. ✅ **Authenticate** with Google Cloud using Workload Identity
2. ✅ **Enable APIs** as needed
3. ✅ **Create/verify** Artifact Registry repositories
4. ✅ **Build and push** Docker images
5. ✅ **Deploy** to Cloud Run services

## 🔍 **Testing the Fix**

Push your changes to the main branch again. The workflow should now:

1. **Setup Infrastructure** ✅ - No more authentication errors
2. **Build Backend** ✅ - Docker build and push should work
3. **Build Frontend** ✅ - Frontend build context fixed
4. **Deploy Services** ✅ - Both services should deploy successfully

## 📋 **If You Still Get Errors**

If you encounter issues, check:

1. **Repository Name**: Ensure you're pushing to `cuppibla/storygeneration`
2. **Branch**: Workflow triggers on `main` branch
3. **Logs**: Check GitHub Actions logs for specific error messages

The authentication issue should now be resolved! 🎉
