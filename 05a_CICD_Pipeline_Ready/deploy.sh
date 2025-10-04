#!/bin/bash

set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh [staging|prod]"
  exit 1
fi

echo "Deploying StoryGen to $ENV"

# Deploy Backend
echo "Deploying backend..."
gcloud builds submit backend --config backend/cloudbuild.yaml --substitutions=_ENV=$ENV

# Deploy Frontend
# You can uncomment the following lines to deploy the frontend as well
# echo "Deploying frontend..."
# gcloud builds submit frontend --config frontend/cloudbuild.yaml --substitutions=_ENV=$ENV

echo "Deployment to $ENV finished successfully!"
