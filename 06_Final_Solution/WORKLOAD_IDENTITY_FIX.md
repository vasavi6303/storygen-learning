# 🔧 Workload Identity Provider Fix

## Problem Description

When running CI/CD pipelines, you may encounter this error:

```
google-github-actions/auth failed with:
failed to generate Google Cloud federated token for 
//iam.googleapis.com/projects/670096104921/locations/global/workloadIdentityPools/github-pool/providers/github-provider-fixed: 
{"error":"unauthorized_client","error_description":"The given credential is rejected by the attribute condition."}
```

## Root Cause

The Workload Identity Provider has an **attribute condition** that restricts which GitHub repositories can authenticate. The error occurs when:

1. The WIP was configured for a different GitHub repository (e.g., `cuppibla/storygen-exercise`)
2. Your current repository has a different name/owner
3. The attribute condition `assertion.repository=='OLD_REPO'` doesn't match your actual repository

## Automated Fix

### Option 1: Complete Setup (Recommended for new users)

Run the complete CI/CD setup which includes the Workload Identity fix:

```bash
cd 06_Final_Solution
./setup-cicd-complete.sh
```

This script:
- ✅ Sets up CI/CD configuration
- ✅ Automatically detects your GitHub repository
- ✅ Updates Workload Identity Provider with correct attribute condition
- ✅ Configures service account bindings
- ✅ Updates deployment configuration files

### Option 2: Fix Only (For existing setups)

If you already have CI/CD configured and just need to fix the Workload Identity:

```bash
cd 06_Final_Solution
./fix-workload-identity.sh
```

This script:
- ✅ Reads your GitHub repository from `.env` file
- ✅ Updates the Workload Identity Provider attribute condition
- ✅ Ensures service account bindings are correct
- ✅ Updates deployment configuration

### Option 3: Enhanced Test Script

Run the enhanced test script that checks and guides you to the fix:

```bash
cd 06_Final_Solution
./test-env-loading.sh
```

This script now:
- ✅ Tests `.env` file loading
- ✅ Checks Workload Identity Provider configuration
- ✅ Identifies mismatched attribute conditions
- ✅ Provides clear next steps

## How the Fix Works

### 1. Detection
The script automatically detects your GitHub repository from the `.env` file:
```bash
GITHUB_USERNAME="your-username"
GITHUB_REPO="your-repo-name"
```

### 2. Attribute Condition Update
Updates the Workload Identity Provider with the correct condition:
```bash
# Before (causes error)
assertion.repository=='cuppibla/storygen-exercise'

# After (allows your repo)
assertion.repository=='your-username/your-repo-name'
```

### 3. Service Account Binding
Ensures the service account can be impersonated by your repository:
```bash
gcloud iam service-accounts add-iam-policy-binding \
    github-actions@PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/your-username/your-repo-name"
```

### 4. Configuration Update
Updates the deployment configuration file with the correct Workload Identity Provider URL.

## Manual Fix (If Scripts Don't Work)

If you need to fix this manually:

### 1. Get Your Repository Information
```bash
# Your GitHub username
GITHUB_USERNAME="your-username"
# Your repository name  
GITHUB_REPO="your-repo-name"
# Your project ID
PROJECT_ID="your-project-id"
```

### 2. Update Workload Identity Provider
```bash
gcloud iam workload-identity-pools providers update-oidc github-provider-fixed \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --attribute-condition="assertion.repository=='$GITHUB_USERNAME/$GITHUB_REPO'"
```

### 3. Update Service Account Binding
```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

# Add binding
gcloud iam service-accounts add-iam-policy-binding \
    "github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB_USERNAME/$GITHUB_REPO"
```

## Verification

After applying the fix, verify it works:

### 1. Check Current Configuration
```bash
gcloud iam workload-identity-pools providers describe github-provider-fixed \
    --project="$PROJECT_ID" --location="global" \
    --workload-identity-pool="github-pool" \
    --format="value(attributeCondition)"
```

Should output: `assertion.repository=='your-username/your-repo-name'`

### 2. Test CI/CD
1. Commit and push your changes
2. Monitor GitHub Actions workflow
3. Verify authentication succeeds

## Common Issues

### Issue: "Provider not found"
**Solution**: Run the complete setup first:
```bash
./setup-cicd-complete.sh
```

### Issue: "Permission denied"
**Solution**: Ensure you're authenticated with gcloud:
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Issue: "Changes don't take effect"
**Solution**: Changes may take a few minutes to propagate. Wait 2-3 minutes and retry.

### Issue: "Wrong repository detected"
**Solution**: Check your `.env` file has the correct values:
```bash
GITHUB_USERNAME=your-actual-username
GITHUB_REPO=your-actual-repo-name
```

## For New Users - Complete Workflow

For new users setting up CI/CD from scratch:

```bash
# 1. Test configuration
cd 06_Final_Solution
./test-env-loading.sh

# 2. Set up complete CI/CD (includes WIP fix)
./setup-cicd-complete.sh

# 3. Commit and push
git add .
git commit -m "Configure CI/CD with Workload Identity fix"
git push origin main

# 4. Monitor GitHub Actions
# Go to: https://github.com/your-username/your-repo/actions
```

## Prevention

To prevent this issue in the future:
1. Always use the provided setup scripts
2. Ensure your `.env` file has the correct GitHub repository information
3. Run `./test-env-loading.sh` before setting up CI/CD to verify configuration

The automated scripts will ensure the Workload Identity Provider is always configured correctly for your specific repository.
