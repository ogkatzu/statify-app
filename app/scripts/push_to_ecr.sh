#!/bin/bash

# Configuration - UPDATE THESE VALUES
AWS_REGION="us-west-2"
ECR_REPOSITORY_NAME="demo/spotify-app"
AWS_ACCOUNT_ID="123456789012"  # Replace with your AWS account ID

# Build the image
echo "Building Docker image..."
docker buildx build --platform linux/amd64,linux/arm64 -t spotify-app .

# Get ECR login token
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Tag the image
echo "Tagging image..."
docker tag spotify-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest

echo "Tagging image..."
docker tag spotify-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:0.0.4

# Push to ECR
echo "Pushing to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest

echo "Pushing to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:0.0.4

echo "Done! Image pushed to ECR."
echo "Image URI: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest"