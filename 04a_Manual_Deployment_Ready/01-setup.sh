#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Load environment variables
source load-env.sh

echo "Starting GCP setup..."

# 1. Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# 2. Configure gcloud CLI
gcloud config set project $GCP_PROJECT_ID
gcloud config set compute/region $GCP_REGION

# 3. Enable necessary GCP services
echo "Enabling GCP services..."
gcloud services enable \
  run.googleapis.com \
  containerregistry.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  storage-api.googleapis.com

echo "GCP setup complete."

