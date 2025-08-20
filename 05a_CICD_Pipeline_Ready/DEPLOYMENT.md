
# StoryGen Backend Deployment to Cloud Run (WebSocket Enabled)

This document provides step-by-step instructions for deploying the containerized, WebSocket-enabled backend to Google Cloud Run.

## Prerequisites

1.  **Google Cloud SDK**: Make sure you have the `gcloud` CLI installed and authenticated.
    ```bash
    gcloud auth login
    gcloud auth application-default login
    ```

2.  **Enable APIs**: Ensure the required APIs are enabled for your project.
    ```bash
    gcloud services enable run.googleapis.com
    gcloud services enable artifactregistry.googleapis.com
    gcloud services enable cloudbuild.googleapis.com
    ```

3.  **Set Environment Variables**: Set the following environment variables in your terminal. **Remember to replace `"sdlc-468305"` with your actual project ID if it's different.**

    ```bash
    export PROJECT_ID="sdlc-468305"
    export REGION="us-central1" # Or your preferred region
    export REPO_NAME="storygen-backend"
    export IMAGE_NAME="storygen-api-ws" # Use a distinct name for the WebSocket version
    ```

## Deployment Steps

### 1. Create an Artifact Registry Repository

This is where your Docker images will be stored. If you've already created this repository in previous steps, you can skip this.

```bash
gcloud artifacts repositories create ${REPO_NAME} \
    --repository-format=docker \
    --location=${REGION} \
    --description="Docker repository for StoryGen backend"
```

### 2. Configure Docker Authentication

Configure Docker to use your `gcloud` credentials to push images to the repository.

```bash
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

### 3. Build the Docker Image

Navigate to the `backend` directory and build the Docker image using Cloud Build. This is the recommended way to build images for Google Cloud.

```bash
cd backend

gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest .

cd ..
```

### 4. Deploy to Cloud Run

Deploy the container image you just built to Cloud Run. This command creates a new service and enables WebSocket support.

**Important**: You must also pass the necessary environment variables for your application to function correctly.

```bash
# Replace with the name of the bucket you created for storing generated media
export GENMEDIA_BUCKET="sdlc-468305-genmedia" 

gcloud run deploy storygen-backend-ws-service \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest \
    --platform=managed \
    --region=${REGION} \
    --allow-unauthenticated \
    --set-env-vars="GENMEDIA_BUCKET=gs://${GENMEDIA_BUCKET}" \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID}" \
    --port=8080 \
    --session-affinity
```
*   `--allow-unauthenticated`: This makes your service publicly accessible so the frontend can connect.
*   `--set-env-vars`: This passes the necessary environment variables to your running container.
*   `--session-affinity`: This is **critical for WebSockets**. It ensures that all requests from a given client are routed to the same container instance.

### 5. Verify Deployment

Once the deployment is complete, `gcloud` will provide you with a **Service URL**. You can test the `/health` endpoint to ensure it's running:
```bash
curl https://your-service-url-xxxx.a.run.app/health
```

Your WebSocket endpoint will be at `wss://your-service-url-xxxx.a.run.app/ws/{user_id}`. You will use this URL in your frontend application.

This concludes the deployment process. Your backend is now running as a scalable, WebSocket-enabled service on Cloud Run. 