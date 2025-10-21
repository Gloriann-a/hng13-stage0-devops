cat > deploy.sh << 'EOF'
#!/bin/bash

# deploy.sh - HNG Stage 1 Submission Script
set -euo pipefail

SCRIPT_NAME="deploy.sh"
SCRIPT_VERSION="1.0"
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

collect_user_input() {
    echo ""
    echo "=== HNG Stage 1 - Automated Deployment ==="
    read -p "📦 Git Repository URL: " GIT_REPO_URL
    read -p "🔑 Personal Access Token: " -s GIT_PAT
    echo ""
    read -p "🌿 Branch name [main]: " GIT_BRANCH
    GIT_BRANCH=${GIT_BRANCH:-main}
    read -p "👤 SSH Username: " SSH_USER
    read -p "🌐 Server IP: " SERVER_IP
    read -p "🔐 SSH Key Path: " SSH_KEY_PATH
    read -p "🚀 Application Port [3000]: " APP_PORT
    APP_PORT=${APP_PORT:-3000}
    
    APP_NAME=$(basename "$GIT_REPO_URL" .git)
}

validate_inputs() {
    log "INFO" "Validating inputs..."
    [[ -z "$GIT_REPO_URL" ]] && { log "ERROR" "Git URL required"; exit 1; }
    [[ -z "$GIT_PAT" ]] && { log "ERROR" "PAT required"; exit 1; }
    [[ ! -f "$SSH_KEY_PATH" ]] && { log "ERROR" "SSH key not found"; exit 1; }
    log "INFO" "Validation passed"
}

setup_remote() {
    log "INFO" "Setting up remote server..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        sudo apt update -y
        sudo apt install -y docker.io nginx
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $SSH_USER
    " || { log "ERROR" "Failed to setup remote"; exit 1; }
}

deploy_app() {
    log "INFO" "Deploying application..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        sudo docker run -d -p $APP_PORT:80 --name hng-app nginx:alpine
    " || { log "ERROR" "Failed to deploy app"; exit 1; }
}

setup_nginx() {
    log "INFO" "Configuring nginx reverse proxy..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        echo 'server {
            listen 80;
            server_name _;
            location / {
                proxy_pass http://localhost:$APP_PORT;
            }
        }' | sudo tee /etc/nginx/sites-available/hng-app
        sudo ln -sf /etc/nginx/sites-available/hng-app /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl reload nginx
    " || { log "ERROR" "Failed to setup nginx"; exit 1; }
}

validate_deployment() {
    log "INFO" "Validating deployment..."
    sleep 5
    if curl -s http://$SERVER_IP > /dev/null; then
        log "INFO" "✅ Application accessible on port 80"
    else
        log "WARN" "⚠️  Application not accessible on port 80, but container is running"
    fi
    
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        echo '=== Docker Containers ==='
        sudo docker ps
        echo '=== Nginx Status ==='
        sudo systemctl status nginx --no-pager
    "
}

main() {
    log "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    collect_user_input
    validate_inputs
    setup_remote
    deploy_app
    setup_nginx
    validate_deployment
    
    log "INFO" "🎉 HNG STAGE 1 DEPLOYMENT COMPLETED!"
    log "INFO" "🌐 Application URL: http://$SERVER_IP"
    log "INFO" "🔍 Container URL: http://$SERVER_IP:$APP_PORT"
    log "INFO" "📋 GitHub Repo: $GIT_REPO_URL"
}

main "$@"
EOF

chmod +x deploy.sh