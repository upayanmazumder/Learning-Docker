#!/bin/bash

# GitHub repository to monitor
REPO="https://github.com/upayanmazumder/Learning-Docker"
IMAGE="ghcr.io/upayanmazumder/learning-docker:latest"
CONTAINER_NAME="learning-docker-container"
WEBHOOK_URL="https://discord.com/api/webhooks/1289800565983019119/_hS5-qQ6xsYW2L2vk8UaXXA_BNXITBfDnS_PVru5ztHIjvtGpLphvZSiZFlgQJHoyTmt"
LOG_FILE="docker_monitor.log"
PORT=3000

# Function to log messages with timestamps
log_message() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to send messages to Discord as embeds
send_to_discord() {
    local title="$1"
    local description="$2"
    local color="$3"
    local github_url="$4"
    local docker_url="$5"

    curl -H "Content-Type: application/json" -X POST -d "{
        \"embeds\": [{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"color\": $color,
            \"fields\": [
                {
                    \"name\": \"GitHub Commit\",
                    \"value\": \"[View Commit]($github_url)\",
                    \"inline\": true
                },
                {
                    \"name\": \"Docker Image\",
                    \"value\": \"[View Image]($docker_url)\",
                    \"inline\": true
                }
            ]
        }]
    }" "$WEBHOOK_URL"
}

# Function to check the latest commit hash
get_latest_commit() {
    git ls-remote "$REPO" HEAD | awk '{ print $1 }'
}

# Function to safely stop and remove the old container
stop_and_remove_container() {
    local container_name="$1"
    local running_container_id=$(docker ps -q -f name="$container_name")
    if [ "$running_container_id" ]; then
        log_message "Stopping the old container: $container_name"
        send_to_discord "Stopping Old Container" "Stopping the old container..." 15158332 "" "" # Yellow
        docker stop --time 30 "$container_name" || {
            log_message "Error stopping container."
            send_to_discord "Error Stopping Container" "Failed to stop the old container." 15158332 "" "" # Red
            return 1
        }

        log_message "Removing the old container: $container_name"
        docker rm "$container_name" || {
            log_message "Error removing container."
            send_to_discord "Error Removing Container" "Failed to remove the old container." 15158332 "" "" # Red
            return 1
        }
        log_message "Old container removed: $container_name"
    fi
}

# Function to check if the port is free
is_port_free() {
    local port="$1"
    if lsof -i:"$port" -t > /dev/null; then
        log_message "Port $port is in use. Exiting."
        send_to_discord "Port in Use" "Port $port is already in use. Cannot start container." 15158332 "" "" # Red
        return 1
    fi
}

# Store the initial commit hash
latest_commit=$(get_latest_commit)
log_message "Initial commit hash: $latest_commit"
send_to_discord "Monitoring Started" "Monitoring started for $REPO. Initial commit: $latest_commit." 3066993 "" "" # Green

while true; do
    sleep 60

    # Get the latest commit hash
    current_commit=$(get_latest_commit)
    github_commit_url="$REPO/commit/$current_commit"

    # Check if the commit hash has changed
    if [ "$latest_commit" != "$current_commit" ]; then
        log_message "New commit detected: $current_commit"
        send_to_discord "New Commit Detected" "New commit detected: $current_commit. Pulling the latest Docker image..." 15158332 "$github_commit_url" "" # Yellow

        # Stop and remove the old container
        stop_and_remove_container "$CONTAINER_NAME" || continue

        # Pull the latest Docker image
        log_message "Pulling the latest Docker image: $IMAGE"
        if docker pull "$IMAGE"; then
            log_message "Successfully pulled the latest image: $IMAGE"
            docker_image_url="https://github.com/upayanmazumder/Learning-Docker/packages"
            send_to_discord "Image Pulled" "Successfully pulled the latest image: $IMAGE." 3066993 "$github_commit_url" "$docker_image_url" # Green

            # Check if the port is free before running the container
            is_port_free "$PORT" || continue

            # Ensure any existing stopped container with the same name is removed
            stopped_container_id=$(docker ps -a -q -f name="$CONTAINER_NAME")
            if [ "$stopped_container_id" ]; then
                log_message "Removing stopped container with the same name: $CONTAINER_NAME"
                docker rm "$stopped_container_id"
            fi

            # Run the new container
            log_message "Running new container: $CONTAINER_NAME"
            if docker run -d --name "$CONTAINER_NAME" -p "$PORT":3000 --health-cmd="curl -f http://localhost:3000 || exit 1" --health-interval=30s --health-retries=3 "$IMAGE"; then
                log_message "New container is now running: $CONTAINER_NAME"
                send_to_discord "Container Running" "New container is now running: $CONTAINER_NAME." 3066993 "$github_commit_url" "$docker_image_url" # Green
            else
                log_message "Failed to run the new container: $CONTAINER_NAME"
                send_to_discord "Failed to Run Container" "Failed to run the new container." 15158332 "$github_commit_url" "$docker_image_url" # Red
            fi
        else
            log_message "Failed to pull the latest image: $IMAGE"
            send_to_discord "Failed to Pull Image" "Failed to pull the latest image: $IMAGE." 15158332 "$github_commit_url" "" # Red
        fi

        # Update the latest commit hash
        latest_commit="$current_commit"
        log_message "Updated commit hash to: $latest_commit"
    fi
done
