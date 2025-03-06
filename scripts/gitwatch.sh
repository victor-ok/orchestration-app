#!/bin/bash

# Configuration
GITEA_URL="https://gitea.com/"  # Replace with your Gitea instance URL
USERNAME="victor-ok"               # Gitea username
TOKEN="8f871a0909769c938cc379bba396cc2146dd19e7"               # Personal Access Token (PAT)
#d911b729947ffc27fb855fd5a88699e7c01b8809
WATCH_BRANCH="main"                    # The branch to watch
CHECK_INTERVAL=5                       # Interval to check for updates (seconds)
CLONE_DIR="$HOME/gitea_repos"           # Local directory to store cloned repos
HOME_DIR="$HOME"

#initiate the first instnace as a master node
source "$HOME/mastermode"

# Ensure clone directory exists
mkdir -p "$CLONE_DIR"

# Function to fetch repositories from Gitea
get_repos() {
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" "$GITEA_URL/api/v1/user/repos")

    # Validate JSON response
    if echo "$RESPONSE" | jq empty 2>/dev/null; then
        echo "$RESPONSE" | jq -r '.[].name'  # Extract only repo names
    else
        echo "Error: Invalid API response. Please check authentication and permissions."
        exit 1
    fi
}

# Function to check for new repositories
watch_new_repos() {
    echo "Watching for new repositories on Gitea..."
    local existing_repos=()

    while true; do
        new_repos=($(get_repos))

        for repo in "${new_repos[@]}"; do
            repo_name=$(basename "$repo")

            # Check if repo is already cloned
            if [[ ! " ${existing_repos[*]} " =~ " $repo_name " ]]; then
                echo "New repo found: $repo_name. Cloning..."
                git clone "$GITEA_URL/$USERNAME/$repo_name.git" "$CLONE_DIR/$repo_name"
                existing_repos+=("$repo_name")
                # Start watching branch for new commits
                watch_branch "$repo_name" &
            fi
        done

        sleep "$CHECK_INTERVAL"
    done
}

# Function to watch a branch for new commits
watch_branch() {
    local repo_name="$1"
    local repo_path="$CLONE_DIR/$repo_name"

    echo "Watching branch '$WATCH_BRANCH' in repo: $repo_name"

    cd "$repo_path" || exit

    while true; do
        git fetch origin "$WATCH_BRANCH"

        LOCAL_COMMIT=$(git rev-parse HEAD)
        REMOTE_COMMIT=$(git rev-parse origin/"$WATCH_BRANCH")

        if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
            echo "New commits found in $repo_name! Pulling updates..."
            git pull origin "$WATCH_BRANCH"

            
            cd "$HOME_DIR/orchestration-app/" || exit
            echo "Triggering deployment script..."
            python3 orch.py 
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Run the watcher
watch_new_repos
