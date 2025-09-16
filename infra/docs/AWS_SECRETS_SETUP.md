# AWS Secrets Manager Setup for Spotify Application

## Overview

The Terraform configuration now pulls Spotify application credentials from AWS Secrets Manager instead of using hardcoded values. This document explains how to set up the required secret.

## Secret Configuration

### Secret Name
```
saar/spotify/secret
```

### Required JSON Structure
The secret must contain a JSON object with the following structure:

```json
{
  "spotify_client_id": "your_spotify_client_id_here",
  "spotify_secret": "your_spotify_client_secret_here",
  "spotify_redirect_uri": "http://127.0.0.1:8000/callback"
}
```

## Creating the Secret

### Option 1: AWS CLI
```bash
# Create the secret with initial values
aws secretsmanager create-secret \
  --name "saar/spotify/secret" \
  --description "Spotify application credentials for Saar portfolio app" \
  --secret-string '{
    "spotify_client_id": "your_spotify_client_id_here",
    "spotify_secret": "your_spotify_client_secret_here",
    "spotify_redirect_uri": "http://127.0.0.1:8000/callback"
  }' \
  --region ap-south-1
```

### Option 2: AWS Console
1. Go to AWS Secrets Manager in the `ap-south-1` region
2. Click "Store a new secret"
3. Select "Other type of secret"
4. Choose "Plaintext" and paste the JSON structure above
5. Name the secret: `saar/spotify/secret`
6. Add description: "Spotify application credentials for Saar portfolio app"
7. Complete the creation process

## Updating the Secret

### Using AWS CLI
```bash
# Update existing secret values
aws secretsmanager update-secret \
  --secret-id "saar/spotify/secret" \
  --secret-string '{
    "spotify_client_id": "your_new_client_id",
    "spotify_secret": "your_new_client_secret",
    "spotify_redirect_uri": "http://127.0.0.1:8000/callback"
  }' \
  --region ap-south-1
```

## How Terraform Uses the Secret

1. **Data Sources**: Terraform fetches the secret using `aws_secretsmanager_secret` and `aws_secretsmanager_secret_version`
2. **JSON Parsing**: The secret string is parsed as JSON using `jsondecode()`
3. **Kubernetes Secret**: Values are mapped to a Kubernetes secret named `spotify-credentials`
4. **Namespace**: Secret is created in the namespace specified by `var.app_namespace` (default: `spotify-app`)

## Kubernetes Secret Mapping

The AWS secret fields are mapped to Kubernetes secret keys as follows:

| AWS Secret Field | Kubernetes Secret Key | Default Value |
|------------------|----------------------|---------------|
| `spotify_client_id` | `SPOTIFY_CLIENT_ID` | *Required* |
| `spotify_secret` | `SPOTIFY_CLIENT_SECRET` | *Required* |
| `spotify_redirect_uri` | `SPOTIFY_REDIRECT_URI` | `http://127.0.0.1:8000/callback` |

## Required IAM Permissions

Ensure your Terraform execution role has the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-south-1:*:secret:saar/spotify/secret*"
    }
  ]
}
```

## Troubleshooting

### Common Issues

1. **Secret Not Found**
   - Verify the secret exists: `aws secretsmanager describe-secret --secret-id "saar/spotify/secret" --region ap-south-1`
   - Check the region (must be `ap-south-1`)

2. **Invalid JSON Format**
   - Validate JSON structure using `jq` or online JSON validator
   - Ensure field names match exactly (case-sensitive)

3. **Permission Denied**
   - Verify IAM permissions for the Terraform execution role
   - Check the secret ARN in the policy

4. **Missing Required Fields**
   - Ensure both `spotify_client_id` and `spotify_secret` are present
   - The `spotify_redirect_uri` is optional and will default if not provided

### Verification Commands

```bash
# Check if secret exists
aws secretsmanager describe-secret --secret-id "saar/spotify/secret" --region ap-south-1

# Get secret value (be careful with this in production)
aws secretsmanager get-secret-value --secret-id "saar/spotify/secret" --region ap-south-1

# Test JSON parsing
aws secretsmanager get-secret-value --secret-id "saar/spotify/secret" --region ap-south-1 --query SecretString --output text | jq .
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant necessary IAM permissions
2. **Rotation**: Consider enabling automatic rotation for production secrets
3. **Monitoring**: Enable CloudTrail logging for secret access
4. **Access Control**: Use resource-based policies if needed for cross-account access
5. **Backup**: Secrets Manager automatically handles versioning and backup