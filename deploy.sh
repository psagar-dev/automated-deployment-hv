#!/bin/bash

GIT_REPO="psagar-dev/automated-deployment-hv"
BRANCH_NAME="main"
GITHUB_URL="https://github.com/$GIT_REPO.git"
GITHUB_API_URL="https://api.github.com/repos/$GIT_REPO/commits/$BRANCH_NAME"
DEPLOY_DIR="/var/www/html"
PROJECT_DIR="automated-deployment-hv"
LAST_COMMIT_DIR="/home/ci-cd"
LAST_COMMIT_FILE="$LAST_COMMIT_DIR/last_commit.txt"
# set -x

if [[ ${UID} -ne 0 ]]; then
    echo "Please Run with sudo or root"
    exit 1
fi

check_nginx_installed() {
    if command -v nginx &>/dev/null; then
        echo "✅ Nginx is installed."
    else
        echo "Nginx is not installed. Installing..."
        sudo apt update && sudo apt install -y nginx
    fi
}

check_nginx() {
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

    [[ ! -d $DEPLOY_DIR ]] && echo "✘ Directory does not exist: $DEPLOY_DIR" && exit 1

    mkdir -p $DEPLOY_DIR/$PROJECT_DIR
}

setup_permission() {
    echo "Setting permissions..."
    sudo chown -R www-data:www-data "$DEPLOY_DIR/$PROJECT_DIR"
    sudo chmod -R 755 "$DEPLOY_DIR/$PROJECT_DIR"
}

check_for_updates() {
    local latest_commit
    local last_commit

    latest_commit=$(get_latest_commit)
    last_commit=$(read_last_commit)

    if [[ "$latest_commit" != "$last_commit" ]]; then
        echo "🚀 New commit detected! Deploying changes..."

        cd "$DEPLOY_DIR/$PROJECT_DIR" || exit

        if sudo git rev-parse --is-inside-work-tree &>/dev/null; then
            git fetch origin
            git reset --hard "origin/$BRANCH_NAME"
        else
            echo "Cloning repository into $DEPLOY_DIR/$PROJECT_DIR..."
            git clone $GITHUB_URL .
        fi

        write_last_commit "$latest_commit"
    else
        echo "✅ No new changes found."
    fi
}

setup_package() {
    if ! command -v jq &>/dev/null; then
        sudo apt install -y jq
    fi
}

check_nginx_installed
check_nginx
setup_package
setup_environment
setup_permission
check_for_updates

echo "Restarting Nginx to deploy changes..."
systemctl restart nginx
echo "✅ Deployment complete."