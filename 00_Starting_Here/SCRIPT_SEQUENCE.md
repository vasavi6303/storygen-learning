# 🚀 StoryGen Setup Script Sequence

## For New Users (Complete Setup)

Run these scripts in order for a complete setup from scratch:

### 1. Infrastructure Setup
```bash
./setup-direct.sh
```
- ⏱️ **Time:** ~2 minutes
- 🎯 **Purpose:** Creates all GCP infrastructure, Workload Identity, permissions
- 📋 **Output:** `setup-summary-{PROJECT_ID}.txt`

### 2. API Key Setup  
```bash
./setup-api-key.sh
```
- ⏱️ **Time:** ~1 minute  
- 🎯 **Purpose:** Securely stores Gemini API key in Secret Manager
- 🔑 **Input:** Your Gemini API key from [aistudio.google.com](https://aistudio.google.com/)

### 3. CI/CD Configuration
```bash
./setup-cicd-config.sh
```
- ⏱️ **Time:** ~30 seconds
- 🎯 **Purpose:** Generates deployment config for environment-based CI/CD
- 📄 **Output:** `.github/config/deployment.yml`

### 4. Deploy
```bash
git add .github/config/deployment.yml
git commit -m "Add CI/CD deployment configuration"  
git push origin main
```
- ⏱️ **Time:** ~5-8 minutes (automatic)
- 🚀 **Result:** Fully deployed application with CI/CD

---

## For Existing Users (Updates)

If you already have infrastructure set up:

### Option A: Full Regeneration
```bash
./setup-direct.sh         # Updates infrastructure
./setup-api-key.sh        # Updates API key (optional)
./setup-cicd-config.sh    # Regenerates CI/CD config
```

### Option B: Just CI/CD Config
```bash
./setup-cicd-config.sh    # Only regenerate CI/CD config
```

---

## Script Dependencies

```
setup-direct.sh (foundation)
    ↓
setup-api-key.sh (requires Secret Manager from step 1)  
    ↓
setup-cicd-config.sh (requires all infrastructure from steps 1-2)
    ↓
git push (triggers deployment)
```

---

## What Each Script Does

| Script | Creates | Validates | Time |
|--------|---------|-----------|------|
| `setup-direct.sh` | Workload Identity, Service Account, Bucket, Secret Manager, APIs | Project access, gcloud auth | ~2 min |
| `setup-api-key.sh` | API key in Secret Manager | API key format, Gemini connection | ~1 min |
| `setup-cicd-config.sh` | `.github/config/deployment.yml` | All infrastructure exists | ~30 sec |

---

## Environment File (.env)

Make sure you have this in the parent directory:

```bash
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GITHUB_USERNAME=your-github-username
GITHUB_REPO=your-repo-name  
GENMEDIA_BUCKET=your-bucket-name
SECRET_MANAGER=your-secret-name
GOOGLE_API_KEY=your-api-key
```

---

## Success Indicators

After each script, you should see:

✅ **setup-direct.sh:** "Complete Setup Finished!" + summary file created
✅ **setup-api-key.sh:** "API key successfully stored and validated"  
✅ **setup-cicd-config.sh:** "CI/CD Configuration Complete!" + config file created
✅ **git push:** GitHub Actions workflow runs successfully

---

## Quick Troubleshooting

**Script fails?** 
- Check you're authenticated: `gcloud auth login`
- Check project access: `gcloud config set project YOUR_PROJECT_ID`
- Check .env file exists and has correct values

**CI/CD fails?**
- Ensure config file is committed: `git status`
- Check workflow file syntax is valid
- Verify all infrastructure exists

**Need help?** See `SETUP_GUIDE.md` for detailed troubleshooting.

---

**🎯 Total Time: ~5 minutes from clone to deployment!**
