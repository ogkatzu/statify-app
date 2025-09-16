# SSH Authentication Setup for ArgoCD GitOps Repository

## Overview

ArgoCD requires SSH key authentication to access your private GitOps repository. This guide shows how to set up SSH keys for secure repository access.

## Quick Setup Steps

1. **Generate SSH Key Pair**
2. **Add Public Key to GitHub Repository**
3. **Store Private Key in AWS Secrets Manager**
4. **Deploy with Terraform**

## Detailed Instructions

### 1. Generate SSH Key Pair

Generate a dedicated SSH key pair for ArgoCD:

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "argocd@saar-spotify-cluster" -f ~/.ssh/argocd_rsa

# Or generate RSA key if ED25519 is not supported
ssh-keygen -t rsa -b 4096 -C "argocd@saar-spotify-cluster" -f ~/.ssh/argocd_rsa
```

This creates two files:
- `~/.ssh/argocd_rsa` (private key)
- `~/.ssh/argocd_rsa.pub` (public key)

### 2. Add Public Key to GitHub Repository

#### Option A: Deploy Key (Recommended)
1. Go to your GitOps repository: `https://github.com/ogkatzu/spotify-stats-gitops`
2. Navigate to **Settings** → **Deploy keys**
3. Click **Add deploy key**
4. Set title: `ArgoCD Saar Spotify Cluster`
5. Paste the contents of `~/.ssh/argocd_rsa.pub`
6. **Do NOT** check "Allow write access" (read-only is sufficient)
7. Click **Add key**

#### Option B: SSH Key in GitHub Account
1. Go to **GitHub Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Set title: `ArgoCD Saar Spotify Cluster`
4. Paste the contents of `~/.ssh/argocd_rsa.pub`
5. Click **Add SSH key**

### 3. Store Private Key in AWS Secrets Manager

#### Option A: Store as Plain Text (Strongly Recommended)

This is the simplest and most reliable method:

```bash
# Create the secret with private key as plain text
aws secretsmanager create-secret \
  --name "saar/argocd/ssh-key" \
  --description "SSH private key for ArgoCD to access GitOps repository" \
  --secret-string file://~/.ssh/argocd_rsa \
  --region ap-south-1
```

#### Option B: Store as JSON (Advanced - Not Recommended)

⚠️ **Warning**: JSON format is error-prone due to newline escaping issues. Only use if you have specific requirements.

```bash
# Method 1: Using jq for proper JSON escaping (recommended if using JSON)
jq -n --rawfile key ~/.ssh/argocd_rsa '{"private_key": $key}' | \
aws secretsmanager create-secret \
  --name "saar/argocd/ssh-key" \
  --description "SSH private key for ArgoCD to access GitOps repository" \
  --secret-string file:///dev/stdin \
  --region ap-south-1

# Method 2: Manual escaping (more error-prone)
PRIVATE_KEY=$(cat ~/.ssh/argocd_rsa | sed ':a;N;$!ba;s/\n/\\n/g')
aws secretsmanager create-secret \
  --name "saar/argocd/ssh-key" \
  --description "SSH private key for ArgoCD to access GitOps repository" \
  --secret-string "{\"private_key\":\"$PRIVATE_KEY\"}" \
  --region ap-south-1
```

**Using AWS Console (Plain Text Method):**
1. Go to AWS Secrets Manager in `ap-south-1` region
2. Click **Store a new secret**
3. Select **Other type of secret**
4. Choose **Plaintext** and paste the entire private key content:
   ```
   -----BEGIN OPENSSH PRIVATE KEY-----
   YOUR_PRIVATE_KEY_CONTENT_HERE
   -----END OPENSSH PRIVATE KEY-----
   ```
5. Name: `saar/argocd/ssh-key`
6. Description: `SSH private key for ArgoCD to access GitOps repository`

### 4. Test SSH Connection

Test the SSH connection locally:

```bash
# Test SSH connection to GitHub
ssh -T -i ~/.ssh/argocd_rsa git@github.com

# Expected output:
# Hi ogkatzu/spotify-stats-gitops! You've successfully authenticated, but GitHub does not provide shell access.
```

### 5. Deploy with Terraform

Now deploy your infrastructure:

```bash
cd infra
./deploy.sh
```

## AWS Secret Structure

The AWS secret `saar/argocd/ssh-key` can be stored in two formats:

### Format 1: Plain Text (Recommended)
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
...
Your full private key content here
...
-----END OPENSSH PRIVATE KEY-----
```

### Format 2: JSON (Alternative)
```json
{
  "private_key": "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz\n...\nYour full private key content here\n...\n-----END OPENSSH PRIVATE KEY-----"
}
```

**Important Notes:**
- Plain text format is simpler and avoids JSON escaping issues
- If using JSON format, preserve all newlines in the key (use `\n`)
- Include the entire private key including headers and footers
- Do not include extra whitespace or formatting

## How It Works

1. **Terraform** creates a Kubernetes secret in the `argocd` namespace
2. **Secret Labels**: `argocd.argoproj.io/secret-type: repository` tells ArgoCD this is a repository secret
3. **ArgoCD** automatically discovers and uses the SSH key for repository authentication
4. **App-of-Apps** uses the SSH URL: `git@github.com:ogkatzu/spotify-stats-gitops.git`

## Troubleshooting

### Common Issues

1. **"ssh: no key found" - Most Common Issue**
   This usually means the SSH key format is invalid in the Kubernetes secret.
   
   ```bash
   # Check if secret exists
   kubectl get secret gitops-repo-ssh -n argocd
   
   # Check what ArgoCD actually received as the SSH key
   kubectl get secret gitops-repo-ssh -n argocd -o jsonpath='{.data.sshPrivateKey}' | base64 -d | head -5
   ```
   
   **Expected output:** Should start with `-----BEGIN OPENSSH PRIVATE KEY-----` or `-----BEGIN RSA PRIVATE KEY-----`
   
   **If you see JSON like `{"private_key":"-----BEGIN..."`:** The JSON parsing failed. 
   
   **Quick Fix:**
   ```bash
   # Get your private key and store it as plain text
   aws secretsmanager update-secret \
     --secret-id "saar/argocd/ssh-key" \
     --secret-string file://~/.ssh/argocd_rsa \
     --region ap-south-1
   
   # Then re-run terraform apply
   terraform apply
   ```

2. **"Repository not accessible"**
   ```bash
   # Check if secret exists with correct labels
   kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
   
   # Check secret content (be careful in production)
   kubectl get secret gitops-repo-ssh -n argocd -o yaml
   ```

3. **"Permission denied (publickey)"**
   - Verify public key is added to GitHub repository deploy keys
   - Check private key format in AWS Secrets Manager
   - Ensure SSH URL format is correct: `git@github.com:username/repo.git`
   - Test SSH connection locally: `ssh -T git@github.com`

4. **"Host key verification failed"**
   - ArgoCD automatically trusts GitHub's host keys
   - If issues persist, check ArgoCD server logs:
   ```bash
   kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd
   ```

5. **JSON Parsing Issues in Terraform**
   If you see Terraform errors about JSON parsing:
   - Switch to plain text storage format
   - Use the provided `jq` command for proper JSON escaping
   - Check AWS secret content for hidden characters

### Verification Commands

```bash
# Check ArgoCD repository connection
kubectl get applications -n argocd
kubectl describe application app-of-apps -n argocd

# Check ArgoCD repository secrets
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository

# View ArgoCD server logs
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd --tail=50

# Test repository access from ArgoCD pod
kubectl exec -it deployment/argocd-server -n argocd -- sh
# Inside the pod:
# ssh -T git@github.com
```

## Security Best Practices

1. **Least Privilege**: Use deploy keys instead of personal SSH keys
2. **Key Rotation**: Regularly rotate SSH keys (especially for production)
3. **Monitoring**: Monitor AWS Secrets Manager access logs
4. **Backup**: Keep secure backup of SSH keys
5. **Access Control**: Limit IAM permissions to specific secrets

## Key Rotation Process

When rotating SSH keys:

1. Generate new SSH key pair
2. Add new public key to GitHub deploy keys
3. Update AWS secret with new private key
4. Remove old public key from GitHub
5. Terraform will automatically detect and apply the change

```bash
# Update existing secret
aws secretsmanager update-secret \
  --secret-id "saar/argocd/ssh-key" \
  --secret-string "{\"private_key\":\"$NEW_PRIVATE_KEY\"}" \
  --region ap-south-1
```