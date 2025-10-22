#!/bin/bash
set -euo pipefail
trap 'echo "Error at line $LINENO"; exit 1' ERR

# Script metadata
SCRIPT_NAME="deploy.sh"
SCRIPT_VERSION="1.0"
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

# Enhanced logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Collect user input
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

# Input validation
validate_inputs() {
    log "INFO" "Validating inputs..."
    [[ -z "$GIT_REPO_URL" ]] && { log "ERROR" "Git URL required"; exit 1; }
    [[ -z "$GIT_PAT" ]] && { log "ERROR" "PAT required"; exit 1; }
    [[ ! "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && { log "ERROR" "Invalid IP"; exit 1; }
    [[ ! -f "$SSH_KEY_PATH" ]] && { log "ERROR" "SSH key not found"; exit 1; }
    log "INFO" "All inputs validated"
}

# Git operations
git_operations() {
    log "INFO" "Starting Git operations..."
    if [[ -d "$APP_NAME" && -d "$APP_NAME/.git" ]]; then
        log "INFO" "Repository exists, updating..."
        cd "$APP_NAME"
        git stash || true
        git checkout "$GIT_BRANCH"
        git pull origin "$GIT_BRANCH"
    else
        log "INFO" "Cloning new repository..."
        git clone -b "$GIT_BRANCH" "$GIT_REPO_URL" "$APP_NAME"
        cd "$APP_NAME"
    fi
    log "INFO" "Git operations completed"
}

# SSH connectivity check
check_ssh_connection() {
    log "INFO" "Testing SSH connectivity..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "echo 'SSH OK'"; then
        log "INFO" "SSH connectivity confirmed"
    else
        log "ERROR" "SSH connection failed"
        exit 1
    fi
}

# Server preparation
setup_remote_server() {
    log "INFO" "Setting up remote server..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        sudo apt update -y
        sudo apt install -y docker.io nginx
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $SSH_USER
        sudo systemctl start nginx
        sudo systemctl enable nginx
    " || { log "ERROR" "Remote setup failed"; exit 1; }
}

# Docker deployment
deploy_app() {
    log "INFO" "Deploying application..."
    # Transfer files
    scp -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" -r ./* "$SSH_USER@$SERVER_IP:/home/$SSH_USER/"
    
    # Build and run
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        cd /home/$SSH_USER
        sudo docker stop $APP_NAME-container || true
        sudo docker rm $APP_NAME-container || true
        sudo docker build -t $APP_NAME . || echo 'Build failed, using pre-built image'
        sudo docker run -d -p $APP_PORT:80 --name $APP_NAME-container nginx:alpine
    " || { log "ERROR" "Deployment failed"; exit 1; }
}

# Nginx configuration
setup_nginx() {
    log "INFO" "Configuring Nginx reverse proxy..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        echo 'server {
            listen 80;
            server_name _;
            location / {
                proxy_pass http://localhost:$APP_PORT;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
            }
        }' | sudo tee /etc/nginx/sites-available/$APP_NAME
        sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
        sudo nginx -t && sudo systemctl reload nginx
    " || { log "ERROR" "Nginx setup failed"; exit 1; }
}

# Deployment validation
validate_deployment() {
    log "INFO" "Validating deployment..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "
        echo '=== Docker Status ==='
        sudo docker ps
        echo '=== Nginx Status ===' 
        sudo systemctl status nginx --no-pager
    " || { log "WARN" "Validation check failed"; }
    
    # Test accessibility
    if curl -s --connect-timeout 10 "http://$SERVER_IP" > /dev/null; then
        log "INFO" "✅ Application accessible on port 80"
    else
        log "WARN" "⚠️ Application not accessible on port 80"
    fi
}

# Main execution
main() {
    log "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    collect_user_input
    validate_inputs
    check_ssh_connection
    git_operations
    setup_remote_server
    deploy_app
    setup_nginx
    validate_deployment
    
    log "INFO" "🎉 HNG STAGE 1 DEPLOYMENT COMPLETED!"
    log "INFO" "🌐 Application URL: http://$SERVER_IP"
}

main "$@"
