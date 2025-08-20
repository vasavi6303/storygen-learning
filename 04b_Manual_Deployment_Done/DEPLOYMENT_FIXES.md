# Deployment Fixes Summary

## Issues Fixed

### 1. Directory Navigation Error
**Problem**: Script failed with `./03-deploy-infrastructure.sh: line 133: cd: frontend: No such file or directory`

**Root Cause**: The script was trying to navigate to `frontend` directory from within `terraform_code` directory.

**Solution**: 
- Fixed navigation paths to properly move between directories
- Added `cd ..` to go back to project root before accessing frontend
- Added `cd ../terraform_code` to return to terraform directory after frontend operations

### 2. Backend URL Mismatch
**Problem**: Frontend showing "Disconnected" because it was built without proper backend URL configuration.

**Root Cause**: 
- Frontend was built without `NEXT_PUBLIC_BACKEND_URL` environment variable
- Next.js requires environment variables to be available at build time for client-side usage
- The frontend defaulted to `localhost:8000` when no backend URL was provided

**Solution**:
- Updated `frontend/Dockerfile` to accept `NEXT_PUBLIC_BACKEND_URL` as build argument
- Created `frontend/cloudbuild.yaml` to properly handle build arguments
- Modified build scripts to pass backend URL during image builds
- Updated deployment script to rebuild frontend when backend URL changes

## Files Modified

### 1. `/03-deploy-infrastructure.sh`
- Fixed directory navigation from `cd frontend` to proper path handling
- Added proper backend URL configuration during frontend rebuild
- Improved error handling and navigation flow

### 2. `/frontend/Dockerfile`
- Added `ARG NEXT_PUBLIC_BACKEND_URL` to accept backend URL during build
- Added `ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}` to set environment variable

### 3. `/frontend/cloudbuild.yaml` (New File)
- Created Cloud Build configuration to handle build arguments
- Properly passes `_BACKEND_URL` substitution to Docker build

### 4. `/02-build-images.sh`
- Updated to use cloudbuild.yaml configuration
- Added placeholder backend URL for initial build

## How the Fix Works

### Build Process Flow:
1. **Initial Build** (`02-build-images.sh`):
   - Builds frontend with placeholder backend URL
   - This ensures the build process works even without a deployed backend

2. **Infrastructure Deployment** (`03-deploy-infrastructure.sh`):
   - Deploys backend and gets actual backend URL
   - Checks if frontend has correct backend URL configured
   - If mismatch detected, rebuilds frontend with correct backend URL
   - Updates Cloud Run service with new image and environment variables

### Frontend Connection Flow:
1. Frontend reads `NEXT_PUBLIC_BACKEND_URL` at build time
2. Uses this URL for API calls and WebSocket connections
3. WebSocket connects to `wss://backend-url/ws/user-id`
4. Health checks validate backend connectivity

## Testing the Fix

After applying these fixes, new users should:

1. Run `./01-setup.sh` (if not already done)
2. Run `./02-build-images.sh` (builds with placeholder URL)
3. Run `./03-deploy-infrastructure.sh` (deploys and fixes frontend URL)

The script will automatically:
- Detect backend URL mismatch
- Rebuild frontend with correct backend URL
- Deploy updated frontend
- Show "✅ Frontend rebuilt and deployed with correct backend URL"

## Expected Behavior

After successful deployment:
- Frontend URL should show connected status (no "Disconnected" message)
- WebSocket connection should establish successfully
- Story generation should work end-to-end
- Health checks should pass

## Prevention for Future Deployments

The fixes ensure that:
1. Directory navigation errors won't occur due to proper path handling
2. Backend URL mismatches are automatically detected and corrected
3. Frontend is always built with the correct backend URL
4. Environment variables are properly set at both build time and runtime
