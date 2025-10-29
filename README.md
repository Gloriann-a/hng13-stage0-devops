README.md
# Blue/Green Deployment Project

This project demonstrates a Blue/Green deployment setup using Docker, Docker Compose, and Nginx for routing traffic between two app versions.

## Requirements
- Docker
- Docker Compose

## Repo Structure


bluegreen-deploy/
├─ docker-compose.yml
├─ .env.example
├─ README.md
├─ nginx.conf.template
└─ (optional) DECISION.md


## Setup Instructions

1. **Clone the repo**
```bash
git clone <your-repo-url>
cd bluegreen-deploy


Copy environment file

cp .env.example .env


Edit .env to set your Docker image names and active pool if needed.

Start containers

docker compose up -d


Check endpoints

# Nginx (frontend)
curl -I localhost:8080

# Blue app
curl -I localhost:8081/version

# Green app
curl -I localhost:8082/version

Notes

Nginx routes traffic to either the Blue or Green app depending on the ACTIVE_POOL environment variable.

/version endpoint on each app shows the release version and pool (blue or green).

Nginx configuration uses envsubst to inject variables from .env.

Optional

You can simulate errors for chaos testing:

curl -X POST http://localhost:8081/chaos/start?mode=error
curl -X POST http://localhost:8082/chaos/stop


