#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Load environment variables
source load-env.sh

echo "Building and pushing Docker images..."

# 1. Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker

# 2. Build, tag, and push the backend Docker image
echo "Building backend image..."
docker build -t $BACKEND_DOCKER_IMAGE ./backend

echo "Pushing backend image to GCR..."
docker push $BACKEND_DOCKER_IMAGE

# 3. Build, tag, and push the frontend Docker image
echo "Building frontend image..."
docker build -t $FRONTEND_DOCKER_IMAGE ./frontend

echo "Pushing frontend image to GCR..."
docker push $FRONTEND_DOCKER_IMAGE

echo "Docker images built and pushed successfully."
