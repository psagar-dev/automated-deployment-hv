#!/bin/bash

GIT_REPO="psagar-dev/automated-deployment-hv"
BRANCH_NAME="main"
GITHUB_URL="https://github.com/$GIT_REPO.git"
GITHUB_API_URL="https://api.github.com/repos/$GIT_REPO/commits/$BRANCH_NAME"
DEPLOY_DIR="/var/www/html"
PROJECT_DIR="automated-deployment-hv"
FULL_DEPLOY_PATH="$DEPLOY_DIR/$PROJECT_DIR"
LAST_COMMIT_DIR="/home/ci-cd"
LAST_COMMIT_FILE="$LAST_COMMIT_DIR/last_commit.txt"
REQUIRED_PACKAGES=("nginx" "curl" "jq" "git")
# set -x

if [[ ${UID} -ne 0 ]]; then
    echo "Please Run with sudo or root"
    exit 1
fi

install_packages() {
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            echo "$package is not installed. Installing..."
            sudo apt-get update && sudo apt-get install -y "$package"
        else
            echo "✅ $package is already installed."
        fi
    done
}

ensure_nginx_running() {
    if systemctl status nginx &>/dev/null; then
        echo "✅ Nginx is running (systemctl)."
    elif service nginx status &>/dev/null; then
        echo "✅ Nginx is running (service)."
    elif pgrep -x nginx &>/dev/null; then
        echo "✅ Nginx process found."
    elif ss -tulnp | grep -E ":(80|443)" | grep nginx &>/dev/null; then
        echo "✅ Nginx is listening on port 80 or 443."
    elif curl -I http://localhost &>/dev/null; then
        echo "✅ Nginx responded successfully."
    else
        echo "❌ Nginx is not running; attempting to restart..."
        systemctl restart nginx
        echo "Nginx restarted successfully."
    fi
}

get_latest_commit() {
    local latest_commit
    latest_commit=$(curl -s $GITHUB_API_URL | jq -r '.sha')

    if [[ "$latest_commit" == "null" || -z "$latest_commit" ]]; then
        echo "❌ Failed to fetch latest commit from GitHub"
        exit 1
    fi

    echo "$latest_commit"
}

read_last_commit() {
    [[ -f "$LAST_COMMIT_FILE" ]] && cat "$LAST_COMMIT_FILE" || echo ""
}

write_last_commit() {
    echo "$1" > "$LAST_COMMIT_FILE"
}

setup_environment() {
    mkdir -p "$LAST_COMMIT_DIR"

    [[ -f "$LAST_COMMIT_FILE" ]] || {
        echo "📄 Creating last commit file: $LAST_COMMIT_FILE"
        touch "$LAST_COMMIT_FILE"
    }

    [[ ! -d $DEPLOY_DIR ]] && echo "✘ Deployment Directory does not exist: $DEPLOY_DIR" && exit 1

    mkdir -p $FULL_DEPLOY_PATH
}

setup_permission() {
    echo "Setting permissions..."
    sudo chown -R $USER:$USER "$FULL_DEPLOY_PATH"
    sudo chmod -R 755 "$FULL_DEPLOY_PATH"
}

deploy_updates() {
    local latest_commit
    local last_commit

    latest_commit=$(get_latest_commit)
    last_commit=$(read_last_commit)

    if [[ "$latest_commit" != "$last_commit" ]]; then
        echo "🚀 New commit detected! Deploying changes..."

        cd "$FULL_DEPLOY_PATH" || exit

        if git config --get remote.origin.url &>/dev/null; then
            git fetch origin
            git reset --hard "origin/$BRANCH_NAME"
        else
            echo "Cloning repository into $FULL_DEPLOY_PATH..."
            git clone $GITHUB_URL .
        fi

        write_last_commit "$latest_commit"
        echo "✅ Deployment successful."
    else
        echo "✅ No new updates found."
    fi
}

install_packages
ensure_nginx_running
setup_environment
setup_permission
deploy_updates

echo "🔄 Restarting Nginx..."
systemctl restart nginx && echo "✅ Deployment complete." || echo "❌ Failed to restart Nginx."