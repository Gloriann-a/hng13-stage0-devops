

##**`README.md`**

Include instructions for anyone to run your project. Example:

````markdown
# Blue/Green Deployment Project

## Requirements
- Docker
- Docker Compose

## Steps to run
1. Clone the repo:
   ```bash
   git clone <your-repo-url>
   cd bluegreen-deploy
````

2. Copy the environment file:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` to set the proper image names and active pool if needed.
3. Start the containers:

   ```bash
   docker compose up -d
   ```
4. Check the endpoints:

   ```bash
   curl -I localhost:8080  # Nginx
   curl -I localhost:8081  # Blue app
   curl -I localhost:8082  # Green app
   ```

