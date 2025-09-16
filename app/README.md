# Spotify Statistics FastAPI Application

A modern web application that integrates with Spotify's Web API to provide personalized music analytics and statistics. Built with FastAPI and designed for containerized deployment.

## Features

- **Spotify OAuth Integration**: Secure authentication with Spotify accounts
- **Music Analytics**: Track your top songs, artists, and genres
- **Real-time Data**: Live fetching from Spotify Web API
- **Containerized**: Docker-ready with multi-service setup
- **Production Ready**: Nginx reverse proxy with SSL support

## API Endpoints

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/` | GET | Home page with login option |
| `/login` | GET | Initiate Spotify OAuth authentication |
| `/callback` | GET | Handle OAuth callback |
| `/dashboard` | GET | User dashboard with statistics |
| `/user/top_tracks` | GET | User's most played tracks |
| `/user/top_artists` | GET | User's favorite artists |
| `/user/top_genres` | GET | Music genre preferences |
| `/user/avg_popularity` | GET | Average popularity score |
| `/metrics` | GET | Prometheus metrics endpoint |
| `/health` | GET | Application health check |
| `/logout` | GET | Clear session and logout |

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Spotify Developer Account (for API credentials)
- Python 3.11+ (for local development)

### Environment Variables

Create a `.env` file with your Spotify application credentials:

```bash
SPOTIFY_CLIENT_ID=your_client_id_here
SPOTIFY_CLIENT_SECRET=your_client_secret_here
SPOTIFY_REDIRECT_URI=http://localhost:8000/callback
MONGO_URL=mongodb://mongodb:27017/
SECRET_KEY=your_secret_key_here
```

### Running with Docker (Recommended)

```bash
# Start the full stack (app + MongoDB + nginx)
docker-compose up

# Start just the app and database
docker-compose up app mongodb

# Build and run manually
docker build -t spotify-app .
docker run -p 8000:8000 --env-file .env spotify-app
```

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py

# Application will be available at http://localhost:8000
```

## Testing

The project includes comprehensive testing with pytest:

```bash
# Run all tests
cd tests && bash test.sh

# Run specific test types
TEST_TYPE=unit bash tests/test.sh      # Unit tests only
TEST_TYPE=integration bash tests/test.sh  # Integration tests only
TEST_TYPE=all bash tests/test.sh       # All tests

# Docker-based testing
docker-compose run test
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Proxy   │───▶│  FastAPI App    │───▶│    MongoDB      │
│   (Port 80)     │    │   (Port 8000)   │    │  (Port 27017)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
    Static Files           Spotify Web API          User Data &
    SSL Termination        OAuth & Analytics        Session Storage
```

### Core Components

- **FastAPI Application** (`main.py`): Main web server with authentication and API routes
- **MongoDB Database**: Stores user profiles and historical music data
- **Nginx Reverse Proxy**: Handles SSL, static files, and load balancing
- **Spotify Integration**: OAuth flow and Web API interactions using Spotipy library

## Development

### Project Structure

```
main/
├── main.py                 # Main FastAPI application
├── requirements.txt        # Python dependencies
├── Dockerfile             # Container image definition
├── docker-compose.yaml    # Multi-service orchestration
├── nginx.conf            # Nginx configuration
├── templates/            # Jinja2 HTML templates
├── static/              # CSS, JS, and images
└── tests/               # Test suite
    ├── test_main.py     # Unit tests
    ├── test_integration.py  # Integration tests
    └── test.sh         # Test runner script
```

### Key Technologies

- **FastAPI**: Modern Python web framework with automatic API docs
- **MongoDB**: Document database with pymongo driver
- **Spotipy**: Spotify Web API integration library
- **Jinja2**: Template engine for HTML rendering
- **Docker**: Containerization and multi-service deployment
- **Nginx**: High-performance reverse proxy and web server
- **Pytest**: Testing framework with fixtures and mocking

## Deployment

The application supports multiple deployment options:

1. **Docker Compose**: Local development and testing
2. **Kubernetes**: Production deployment with Helm charts (see `/gitops` directory)
3. **Cloud Platforms**: AWS EKS, Google GKE, Azure AKS

For production deployment, see the infrastructure and GitOps configurations in the project root.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Make your changes and add tests
4. Run the test suite (`bash tests/test.sh`)
5. Commit your changes (`git commit -m 'Add new feature'`)
6. Push to the branch (`git push origin feature/new-feature`)
7. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.