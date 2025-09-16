from fastapi import FastAPI, Request, Form, HTTPException, Depends, status
from fastapi.responses import HTMLResponse, RedirectResponse, Response
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import spotipy
from spotipy.oauth2 import SpotifyOAuth
from pymongo import MongoClient
import logging
import sys
from datetime import datetime
import os
import secrets
import time
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Configure logging to write to stdout (critical for Kubernetes)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)  # Ensure logs go to stdout
    ]
)
logger = logging.getLogger(__name__)

# Add startup log
logger.info("Starting Spotify Stats App")

# App setup
app = FastAPI()
app.add_middleware(SessionMiddleware, secret_key=os.getenv("SECRET_KEY", secrets.token_hex(32)))

# Prometheus metrics middleware
class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        method = request.method
        path = request.url.path
        
        # Process the request
        response = await call_next(request)
        
        # Record metrics
        duration = time.time() - start_time
        status = str(response.status_code)
        
        http_requests_total.labels(method=method, endpoint=path, status=status).inc()
        http_request_duration_seconds.labels(method=method, endpoint=path).observe(duration)
        
        return response

app.add_middleware(PrometheusMiddleware)

# Mount static files (only if directory exists)
if os.path.exists("static"):
    app.mount("/static", StaticFiles(directory="static"), name="static")
    logger.info("Static files mounted")

templates = Jinja2Templates(directory=os.path.join(os.path.dirname(__file__), "templates"))

# MongoDB setup
MONGO_URL = os.getenv("MONGO_URL", "mongodb://mongodb:27017/")
logger.info(f"Connecting to MongoDB at {MONGO_URL}")
client = MongoClient(MONGO_URL)
db = client.spotify
users_collection = db.users

# Spotify setup - YOU NEED TO SET THESE
SPOTIFY_CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID", "your_client_id")
SPOTIFY_CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET", "your_client_secret") 
SPOTIFY_REDIRECT_URI = os.getenv("SPOTIFY_REDIRECT_URI", "http://127.0.0.1:8000/callback")

logger.info("Spotify OAuth configured")

# Prometheus metrics
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
http_request_duration_seconds = Histogram('http_request_duration_seconds', 'HTTP request duration in seconds', ['method', 'endpoint'])
spotify_api_requests_total = Counter('spotify_api_requests_total', 'Total Spotify API requests', ['endpoint', 'status'])
active_users_total = Gauge('active_users_total', 'Total number of active users')
database_operations_total = Counter('database_operations_total', 'Total database operations', ['operation', 'collection'])

def get_spotify_oauth():
    return SpotifyOAuth(
        client_id=SPOTIFY_CLIENT_ID,
        client_secret=SPOTIFY_CLIENT_SECRET,
        redirect_uri=SPOTIFY_REDIRECT_URI,
        scope="user-top-read"
    )

def get_current_user(request: Request):
    user_id = request.session.get("user_id")
    if not user_id:
        logger.warning("Unauthenticated access attempt")
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    user = users_collection.find_one({"spotify_id": user_id})
    if not user:
        logger.error(f"User {user_id} not found in database")
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/", response_class=HTMLResponse)
async def login_page(request: Request):
    logger.info("Login page accessed")
    return templates.TemplateResponse("login.html", {"request": request})

@app.get("/login")
async def login():
    logger.info("Login initiated")
    sp_oauth = get_spotify_oauth()
    auth_url = sp_oauth.get_authorize_url()
    return RedirectResponse(auth_url)

@app.get("/callback")
async def callback(request: Request, code: str):
    logger.info(f"OAuth callback received with code: {code[:10]}...")
    sp_oauth = get_spotify_oauth()
    token_info = sp_oauth.get_access_token(code)
    
    sp = spotipy.Spotify(auth=token_info['access_token'])
    user_info = sp.current_user()
    
    # Save user to DB
    user_data = {
        "spotify_id": user_info['id'],
        "name": user_info['display_name'],
        "created_at": datetime.now(),
        "access_token": token_info['access_token'],
        "refresh_token": token_info['refresh_token']
    }
    
    users_collection.update_one(
        {"spotify_id": user_info['id']},
        {"$set": user_data},
        upsert=True
    )
    database_operations_total.labels(operation='upsert', collection='users').inc()
    
    # Set session
    request.session["user_id"] = user_info['id']
    
    # Update active users gauge
    active_users_total.set(users_collection.count_documents({}))
    database_operations_total.labels(operation='count', collection='users').inc()
    logger.info(f"User {user_info['id']} ({user_info['display_name']}) logged in successfully")
    
    return RedirectResponse("/dashboard")

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request, user: dict = Depends(get_current_user)):
    logger.info(f"Dashboard accessed by user {user['spotify_id']}")
    return templates.TemplateResponse("dashboard.html", {
        "request": request, 
        "user": user
    })

@app.get("/user/top_tracks")
async def get_top_tracks(user: dict = Depends(get_current_user)):
    logger.info(f"Fetching top tracks for user {user['spotify_id']}")
    
    try:
        sp = spotipy.Spotify(auth=user['access_token'])
        tracks = sp.current_user_top_tracks(limit=10)
        spotify_api_requests_total.labels(endpoint='top_tracks', status='success').inc()
        
        # Save to DB
        track_data = {
            "user_id": user['spotify_id'],
            "type": "tracks",
            "data": tracks['items'],
            "date": datetime.now()
        }
        db.user_data.insert_one(track_data)
        database_operations_total.labels(operation='insert', collection='user_data').inc()
        
        logger.info(f"Successfully retrieved {len(tracks['items'])} top tracks for user {user['spotify_id']}")
        return {"tracks": tracks['items']}
    except Exception as e:
        spotify_api_requests_total.labels(endpoint='top_tracks', status='error').inc()
        logger.error(f"Error fetching top tracks for user {user['spotify_id']}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error fetching top tracks")

@app.get("/user/top_artists")
async def get_top_artists(user: dict = Depends(get_current_user)):
    logger.info(f"Fetching top artists for user {user['spotify_id']}")
    
    try:
        sp = spotipy.Spotify(auth=user['access_token'])
        artists = sp.current_user_top_artists(limit=10)
        spotify_api_requests_total.labels(endpoint='top_artists', status='success').inc()
        
        # Save to DB
        artist_data = {
            "user_id": user['spotify_id'],
            "type": "artists", 
            "data": artists['items'],
            "date": datetime.now()
        }
        db.user_data.insert_one(artist_data)
        database_operations_total.labels(operation='insert', collection='user_data').inc()
        
        logger.info(f"Successfully retrieved {len(artists['items'])} top artists for user {user['spotify_id']}")
        return {"artists": artists['items']}
    except Exception as e:
        spotify_api_requests_total.labels(endpoint='top_artists', status='error').inc()
        logger.error(f"Error fetching top artists for user {user['spotify_id']}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error fetching top artists")

@app.get("/user/top_genres")
async def get_top_genres(user: dict = Depends(get_current_user)):
    logger.info(f"Fetching top genres for user {user['spotify_id']}")
    
    try:
        sp = spotipy.Spotify(auth=user['access_token'])
        artists = sp.current_user_top_artists(limit=10)
        spotify_api_requests_total.labels(endpoint='top_genres', status='success').inc()
        
        # Extract genres from artists
        genre_count = {}
        for artist in artists['items']:
            for genre in artist['genres']:
                genre_count[genre] = genre_count.get(genre, 0) + 1
        
        # Sort by count and return top genres
        top_genres = sorted(genre_count.items(), key=lambda x: x[1], reverse=True)
        
        logger.info(f"Successfully calculated top genres for user {user['spotify_id']}: {len(top_genres)} unique genres")
        return {"genres": [{"name": genre, "count": count} for genre, count in top_genres]}
    except Exception as e:
        spotify_api_requests_total.labels(endpoint='top_genres', status='error').inc()
        logger.error(f"Error fetching top genres for user {user['spotify_id']}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error fetching top genres")

@app.get("/user/avg_popularity")
async def get_avg_popularity(user: dict = Depends(get_current_user)):
    logger.info(f"Calculating average popularity for user {user['spotify_id']}")
    
    try:
        sp = spotipy.Spotify(auth=user['access_token'])
        tracks = sp.current_user_top_tracks(limit=10)
        spotify_api_requests_total.labels(endpoint='avg_popularity', status='success').inc()
        
        # Calculate average popularity
        total_popularity = sum(track['popularity'] for track in tracks['items'])
        avg_popularity = total_popularity / len(tracks['items']) if tracks['items'] else 0
        
        logger.info(f"Average popularity for user {user['spotify_id']}: {avg_popularity}")
        return {"average_popularity": round(avg_popularity, 2)}
    except Exception as e:
        spotify_api_requests_total.labels(endpoint='avg_popularity', status='error').inc()
        logger.error(f"Error calculating average popularity for user {user['spotify_id']}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error calculating average popularity")

@app.delete("/user")
async def delete_user(request: Request, user: dict = Depends(get_current_user)):
    user_id = user['spotify_id']
    logger.info(f"Attempting to delete user {user_id}")
    
    try:
        result = users_collection.delete_one({"spotify_id": user_id})
        database_operations_total.labels(operation='delete', collection='users').inc()
        db.user_data.delete_many({"user_id": user_id})
        database_operations_total.labels(operation='delete_many', collection='user_data').inc()
        
        if result.deleted_count == 0:
            logger.warning(f"User {user_id} not found for deletion")
            raise HTTPException(status_code=404, detail="User not found")
        
        # Clear session
        request.session.clear()
        
        # Update active users gauge
        active_users_total.set(users_collection.count_documents({}))
        database_operations_total.labels(operation='count', collection='users').inc()
        logger.info(f"Successfully deleted user {user_id}")
        return {"message": "User deleted"}
    except Exception as e:
        logger.error(f"Error deleting user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Error deleting user")

@app.get("/logout")
async def logout(request: Request):
    user_id = request.session.get("user_id", "unknown")
    logger.info(f"User {user_id} logged out")
    request.session.clear()
    return RedirectResponse("/")

@app.get("/metrics")
async def get_metrics():
    logger.info("Metrics endpoint accessed")
    # Update the active users gauge
    active_users_total.set(users_collection.count_documents({}))
    database_operations_total.labels(operation='count', collection='users').inc()
    
    # Return Prometheus metrics format
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# Add health check endpoint
@app.get("/health")
async def health_check():
    logger.info("Health check accessed")
    return {"status": "healthy", "timestamp": datetime.now()}

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting uvicorn server on 0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)