#!/bin/bash

# Debug script for ArgoCD SSH authentication issues

echo "=== ArgoCD SSH Debug Script ==="
echo

# Check if ArgoCD namespace exists
echo "1. Checking ArgoCD namespace..."
kubectl get namespace argocd 2>/dev/null || echo "❌ ArgoCD namespace not found"
echo

# Check ArgoCD pods
echo "2. Checking ArgoCD pods status..."
kubectl get pods -n argocd
echo

# Check repository secrets
echo "3. Checking repository secrets..."
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
echo

# Check specific SSH secret
echo "4. Checking SSH key secret..."
if kubectl get secret gitops-repo-ssh -n argocd &>/dev/null; then
    echo "✅ SSH secret 'gitops-repo-ssh' exists"
    echo "Secret data keys:"
    kubectl get secret gitops-repo-ssh -n argocd -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null || echo "Failed to parse secret keys"
    
    # Check if SSH key looks valid
    echo "SSH key format check:"
    SSH_KEY_CONTENT=$(kubectl get secret gitops-repo-ssh -n argocd -o jsonpath='{.data.sshPrivateKey}' | base64 -d)
    SSH_KEY_FIRST_LINE=$(echo "$SSH_KEY_CONTENT" | head -1)
    
    if echo "$SSH_KEY_FIRST_LINE" | grep -q "BEGIN.*PRIVATE KEY"; then
        echo "✅ SSH private key format looks correct"
        echo "Key type: $(echo "$SSH_KEY_FIRST_LINE" | grep -o 'BEGIN.*PRIVATE KEY')"
    else
        echo "❌ SSH private key format issue detected"
        echo "First line content: '$SSH_KEY_FIRST_LINE'"
        
        # Check if it's JSON that wasn't parsed
        if echo "$SSH_KEY_CONTENT" | head -1 | grep -q '^{.*private_key'; then
            echo "🔍 Issue identified: SSH key contains unparsed JSON!"
            echo "This means Terraform JSON parsing failed. The secret contains:"
            echo "$(echo "$SSH_KEY_CONTENT" | head -1 | cut -c1-100)..."
            echo ""
            echo "💡 Solution: Update AWS secret to plain text format and re-run terraform apply"
        fi
    fi
    
    # Show key length for debugging
    echo "SSH key total length: $(echo "$SSH_KEY_CONTENT" | wc -c) characters"
else
    echo "❌ SSH secret 'gitops-repo-ssh' not found"
fi
echo

# Check ArgoCD applications
echo "5. Checking ArgoCD applications..."
kubectl get applications -n argocd
echo

# Check app-of-apps application specifically
echo "6. Checking app-of-apps application details..."
if kubectl get application app-of-apps -n argocd &>/dev/null; then
    echo "Application status:"
    kubectl get application app-of-apps -n argocd -o jsonpath='{.status.sync.status}' && echo
    kubectl get application app-of-apps -n argocd -o jsonpath='{.status.health.status}' && echo
    
    echo "Application source:"
    kubectl get application app-of-apps -n argocd -o jsonpath='{.spec.source.repoURL}' && echo
    
    echo "Recent conditions:"
    kubectl get application app-of-apps -n argocd -o jsonpath='{.status.conditions}' | jq '.' 2>/dev/null || echo "No conditions or jq not available"
else
    echo "❌ app-of-apps application not found"
fi
echo

# Check ArgoCD server logs for SSH errors
echo "7. Checking ArgoCD server logs for SSH errors..."
echo "Recent SSH-related errors:"
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd --tail=50 | grep -i "ssh\|key\|auth" | tail -10
echo

# Check ArgoCD application controller logs
echo "8. Checking ArgoCD application controller logs..."
echo "Recent repository-related errors:"
kubectl logs -l app.kubernetes.io/name=argocd-application-controller -n argocd --tail=50 | grep -i "repo\|ssh\|key\|auth" | tail -10
echo

# Test basic connectivity to GitHub
echo "9. Testing GitHub SSH connectivity..."
if command -v ssh &> /dev/null; then
    echo "Testing SSH connection to GitHub (this should fail with 'Permission denied' but confirm connectivity):"
    ssh -T git@github.com 2>&1 | head -3
else
    echo "SSH command not available for testing"
fi
echo

# AWS Secrets Manager check
echo "10. Checking AWS Secrets Manager (if AWS CLI available)..."
if command -v aws &> /dev/null; then
    echo "Checking if SSH secret exists in AWS:"
    if aws secretsmanager describe-secret --secret-id "saar/argocd/ssh-key" --region ap-south-1 &>/dev/null; then
        echo "✅ AWS secret 'saar/argocd/ssh-key' exists"
        echo "Secret ARN:"
        aws secretsmanager describe-secret --secret-id "saar/argocd/ssh-key" --region ap-south-1 --query 'ARN' --output text 2>/dev/null
    else
        echo "❌ AWS secret 'saar/argocd/ssh-key' not found or not accessible"
    fi
    
    echo "Checking if Spotify secret exists in AWS:"
    if aws secretsmanager describe-secret --secret-id "saar/spotify/secret" --region ap-south-1 &>/dev/null; then
        echo "✅ AWS secret 'saar/spotify/secret' exists"
    else
        echo "❌ AWS secret 'saar/spotify/secret' not found or not accessible"
    fi
else
    echo "AWS CLI not available for testing"
fi
echo

echo "=== Debug Complete ==="
echo
echo "💡 Next steps:"
echo "1. If SSH secret is missing, run: kubectl apply -f your-terraform-outputs"
echo "2. If SSH key format is wrong, check AWS Secrets Manager content"
echo "3. If application is not syncing, check ArgoCD UI at port-forward"
echo "4. For detailed logs: kubectl logs -f -l app.kubernetes.io/name=argocd-application-controller -n argocd"