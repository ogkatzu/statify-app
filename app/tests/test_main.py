import pytest
from unittest.mock import Mock, patch
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app, get_spotify_oauth

def test_get_spotify_oauth():
    oauth = get_spotify_oauth()
    assert oauth.client_id is not None
    assert oauth.scope == "user-top-read"


@patch('main.users_collection')
def test_metrics(mock_users_collection):
    from fastapi.testclient import TestClient
    
    # Mock the MongoDB collection count_documents method
    mock_users_collection.count_documents.return_value = 5
    
    client = TestClient(app)
    
    response = client.get("/metrics")
    assert response.status_code == 200
    
    # Check that response is in Prometheus text format
    content_type = response.headers["content-type"]
    assert content_type.startswith("text/plain; version=0.0.4") and "charset=utf-8" in content_type
    
    # Check that response contains Prometheus metrics
    content = response.text
    assert "http_requests_total" in content
    assert "active_users_total" in content
    assert "spotify_api_requests_total" in content
    assert "database_operations_total" in content
    assert "http_request_duration_seconds" in content
    
    # Verify the mock was called
    mock_users_collection.count_documents.assert_called_once_with({})

@patch('main.users_collection')
def test_metrics_format(mock_users_collection):
    """Test that metrics are properly formatted as Prometheus metrics"""
    from fastapi.testclient import TestClient
    
    # Mock the MongoDB collection count_documents method
    mock_users_collection.count_documents.return_value = 3
    
    client = TestClient(app)
    
    # Make a few requests to generate some metrics
    client.get("/health")
    client.get("/")
    
    response = client.get("/metrics")
    assert response.status_code == 200
    
    content = response.text
    lines = content.split('\n')
    
    # Check for HELP and TYPE declarations (standard Prometheus format)
    help_lines = [line for line in lines if line.startswith('# HELP')]
    type_lines = [line for line in lines if line.startswith('# TYPE')]
    
    assert len(help_lines) > 0, "Should contain HELP lines for metrics"
    assert len(type_lines) > 0, "Should contain TYPE lines for metrics"
    
    # Check that we have actual metric values (not just metadata)
    metric_lines = [line for line in lines if line and not line.startswith('#')]
    assert len(metric_lines) > 0, "Should contain actual metric values"
    
    # Check specific metric patterns
    http_request_metrics = [line for line in metric_lines if 'http_requests_total' in line]
    assert len(http_request_metrics) > 0, "Should have HTTP request metrics"

def test_login_page():
    from fastapi.testclient import TestClient
    client = TestClient(app)
    
    response = client.get("/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]

def test_login_redirect():
    from fastapi.testclient import TestClient
    client = TestClient(app)
    
    response = client.get("/login", follow_redirects=False)
    assert response.status_code == 307
    assert "spotify.com" in response.headers["location"]