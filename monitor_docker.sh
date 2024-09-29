#!/bin/bash

# GitHub repository to monitor
REPO="https://github.com/upayanmazumder/Learning-Docker"
IMAGE="ghcr.io/upayanmazumder/learning-docker:latest"
CONTAINER_NAME="learning-docker-container"
WEBHOOK_URL="https://discord.com/api/webhooks/1289800565983019119/_hS5-qQ6xsYW2L2vk8UaXXA_BNXITBfDnS_PVru5ztHIjvtGpLphvZSiZFlgQJHoyTmt"

# Function to send messages to Discord as embeds
send_to_discord() {
    local title="$1"
    local description="$2"
    local color="$3"
    
    curl -H "Content-Type: application/json" -X POST -d "{
        \"embeds\": [{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"color\": $color
        }]
    }" "$WEBHOOK_URL"
}

# Function to check the latest commit hash
get_latest_commit() {
    git ls-remote "$REPO" HEAD | awk '{ print $1 }'
}

# Store the initial commit hash
latest_commit=$(get_latest_commit)

send_to_discord "Monitoring Started" "Monitoring started for $REPO. Initial commit: $latest_commit." 3066993 # Green

while true; do
    sleep 5

    # Get the latest commit hash
    current_commit=$(get_latest_commit)

    # Check if the commit hash has changed
    if [ "$latest_commit" != "$current_commit" ]; then
        send_to_discord "New Commit Detected" "New commit detected: $current_commit. Pulling the latest Docker image..." 15158332 # Yellow

        # Stop and remove the old container if it exists
        if [ $(docker ps -q -f name="$CONTAINER_NAME") ]; then
            send_to_discord "Stopping Old Container" "Stopping the old container..." 15158332 # Yellow
            docker stop "$CONTAINER_NAME"
            
            # Wait for the container to fully stop before removing
            while [ $(docker ps -q -f name="$CONTAINER_NAME") ]; do
                sleep 1
            done

            send_to_discord "Removing Old Container" "Removing the old container..." 15158332 # Yellow
            docker rm "$CONTAINER_NAME"
            
            send_to_discord "Old Container Removed" "Old container stopped and removed." 3066993 # Green
        fi

        # Pull the latest Docker image
        if docker pull "$IMAGE"; then
            send_to_discord "Image Pulled" "Successfully pulled the latest image: $IMAGE." 3066993 # Green

            # Run the new container
            if docker run -d --name "$CONTAINER_NAME" -p 3000:3000 "$IMAGE"; then
                send_to_discord "Container Running" "New container is now running: $CONTAINER_NAME." 3066993 # Green
            else
                send_to_discord "Failed to Run Container" "Failed to run the new container." 15158332 # Yellow
            fi
        else
            send_to_discord "Failed to Pull Image" "Failed to pull the latest image: $IMAGE." 15158332 # Yellow
        fi

        # Update the latest commit hash
        latest_commit="$current_commit"
    fi
done
