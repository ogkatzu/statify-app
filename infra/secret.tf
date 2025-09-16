# Data source to fetch the secret metadata
data "aws_secretsmanager_secret" "app_secret" {
  name = "saar/spotify/secret"
}

# Data source to fetch the secret value
data "aws_secretsmanager_secret_version" "app_secret" {
  secret_id = data.aws_secretsmanager_secret.app_secret.id
}

# Data source to fetch MongoDB secret metadata
data "aws_secretsmanager_secret" "mongodb_secret" {
  name = "saar/spotify/mongodb"
}

# Data source to fetch MongoDB secret value
data "aws_secretsmanager_secret_version" "mongodb_secret" {
  secret_id = data.aws_secretsmanager_secret.mongodb_secret.id
}

# Parse the JSON secrets
locals {
  secret_data  = jsondecode(data.aws_secretsmanager_secret_version.app_secret.secret_string)
  mongodb_data = jsondecode(data.aws_secretsmanager_secret_version.mongodb_secret.secret_string)
}

# Create namespace for the application
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      name = var.app_namespace
    }
  }
}

# Create Kubernetes secret with Spotify credentials from AWS Secrets Manager
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "spotify-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    SPOTIFY_CLIENT_ID         = local.secret_data.spotify_client_id
    SPOTIFY_CLIENT_SECRET     = local.secret_data.spotify_secret
    SPOTIFY_REDIRECT_URI      = try(local.secret_data.spotify_redirect_uri, "http://127.0.0.1:8000/callback")
    MONGO_USERNAME            = local.mongodb_data.MONGO_USERNAME
    "mongodb-passwords"       = local.mongodb_data.MONGO_PASSWORD
    "mongodb-root-password"   = local.mongodb_data.MONGO_PASSWORD
    "mongodb-replica-set-key" = local.mongodb_data.MONGO_REPLICA_KEY
    SECRET_KEY                = try(local.secret_data.MONGO_SECRET_KEY, "b45d09e6932d872957046273a2abd2e2332e3df1ea00149f0fb728d586639565")
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.app]
}


