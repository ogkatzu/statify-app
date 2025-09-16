import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, Mock
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import app, client as mongo_client

client = TestClient(app)

def test_database_connection():
    """Test that the app can connect to MongoDB and perform a simple query"""
    try:
        # Simple ping to check connection
        mongo_client.admin.command('ping')
        assert True
    except Exception as e:
        pytest.fail(f"Database connection failed: {e}")

def test_login_page():
    response = client.get("/")
    assert response.status_code == 200
    assert "Connect with Spotify" in response.text

def test_login_redirect():
    response = client.get("/login", follow_redirects=False)
    assert response.status_code == 307
    assert "accounts.spotify.com" in response.headers["location"]

def test_static_files():
    """Test that static files are served correctly if the directory exists"""
    if os.path.exists("static"):
        response = client.get("/static/style.css")
        assert response.status_code == 200
        assert "body" in response.text  # Assuming style.css contains body styles
    else:
        pytest.skip("Static files directory does not exist, skipping static files test")

@patch('main.users_collection')
def test_dashboard_user_not_found(mock_collection):
    mock_collection.find_one.return_value = None
    
    response = client.get("/dashboard/fake_user")
    assert response.status_code == 404

@patch('main.users_collection')
def test_get_top_tracks_user_not_found(mock_collection):
    mock_collection.find_one.return_value = None
    
    response = client.get("/user/top_tracks?user_id=fake_user")
    assert response.status_code == 401

@patch('main.users_collection')
def test_get_top_artists_user_not_found(mock_collection):
    mock_collection.find_one.return_value = None
    
    response = client.get("/user/top_artists?user_id=fake_user")
    assert response.status_code == 401