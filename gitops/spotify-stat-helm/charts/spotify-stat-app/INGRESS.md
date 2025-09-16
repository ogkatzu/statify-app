# Ingress Configuration

This Helm chart supports ingress configuration to expose the Spotify application externally through an ingress controller.

## Prerequisites

- NGINX Ingress Controller installed in the cluster
- (Optional) cert-manager for automatic SSL certificate generation
- (Optional) DNS configuration pointing to your ingress controller

## Basic Configuration

### Enable Ingress

Set `ingress.enabled: true` in your values.yaml:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: spotify-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Local Development

For local testing with minikube or kind:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: spotify-app.local
      paths:
        - path: /
          pathType: Prefix
```

Add to your `/etc/hosts` file:
```
127.0.0.1 spotify-app.local
```

## Advanced Configuration

### SSL/TLS with cert-manager

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: spotify-app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: spotify-app-tls
      hosts:
        - spotify-app.example.com
```

### Custom Annotations

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: spotify-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Spotify OAuth Configuration

When ingress is enabled, the Spotify redirect URI is automatically configured to match your ingress hostname:

- **HTTP**: `http://your-hostname/callback`
- **HTTPS**: `https://your-hostname/callback` (when TLS is configured)

### Update Spotify Developer Console

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Select your application
3. Add the redirect URI that matches your ingress configuration:
   - For `spotify-app.example.com`: `https://spotify-app.example.com/callback`
   - For local development: `http://spotify-app.local/callback`

## Configuration Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hostnames and paths | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

## Examples

### Production Setup

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: spotify.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: spotify-app-prod-tls
      hosts:
        - spotify.yourdomain.com
```

### Development/Staging Setup

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: spotify-dev.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

## Troubleshooting

### Common Issues

1. **404 Not Found**
   - Check ingress controller is running: `kubectl get pods -n ingress-nginx`
   - Verify ingress resource: `kubectl describe ingress -n <namespace>`

2. **SSL Certificate Issues**
   - Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
   - Verify certificate: `kubectl describe certificate -n <namespace>`

3. **Spotify OAuth Redirect Mismatch**
   - Ensure redirect URI in Spotify console matches ingress hostname
   - Check configmap values: `kubectl get configmap <app-name>-config -o yaml`

### Useful Commands

```bash
# Check ingress status
kubectl get ingress -n <namespace>

# Describe ingress for debugging
kubectl describe ingress <app-name>-ingress -n <namespace>

# Check service endpoints
kubectl get endpoints -n <namespace>

# Test internal connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>
```