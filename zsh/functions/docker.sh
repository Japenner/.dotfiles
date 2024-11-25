#!/usr/bin/env bash

# Attach to a running Docker container with a shell by name or ID.
docker_shell() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_shell <container_name_or_id>"
    return 1
  fi
  docker exec -it "$1" /bin/bash || docker exec -it "$1" /bin/sh
}

# Build a Docker image from a Dockerfile and tag it with a name.
docker_build() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: docker_build <path_to_dockerfile> <image_name:tag>"
    return 1
  fi
  docker build -t "$2" "$1"
}

# Remove dangling images that are not tagged and not associated with any container.
docker_clean_dangling_images() {
  docker rmi "$(docker images -q -f dangling=true)"
}

# Display Docker disk usage statistics.
docker_disk_usage() {
  docker system df
}

# Run an interactive command inside a Docker container by name or ID.
docker_exec() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: docker_exec <container_name_or_id> <command>"
    return 1
  fi
  docker exec -it "$1" "$2"
}

# Show all Docker images in a readable format.
docker_images() {
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}

# Inspect a Docker container by name or ID.
docker_inspect() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_inspect <container_name_or_id>"
    return 1
  fi
  docker inspect "$1"
}

# Kill all running Docker containers.
docker_kill_all() {
  docker kill "$(docker ps -q)"
}

# Stream logs from a Docker container by name or ID.
docker_logs() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_logs <container_name_or_id>"
    return 1
  fi
  docker logs -f "$1"
}

# Load a Docker image from a file.
docker_load() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_load <input_file>"
    return 1
  fi
  docker load -i "$1"
}

# List all running Docker containers with their names and IDs.
docker_ps() {
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Remove all unused containers, networks, images, and volumes.
docker_prune_all() {
  docker system prune -a --volumes -f
}

# Pull the latest version of a Docker image from Docker Hub.
docker_pull_latest() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_pull_latest <image_name>"
    return 1
  fi
  docker pull "$1:latest"
}

# Restart Docker Desktop on macOS or the Docker service on Linux.
docker_restart() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    osascript -e 'quit app "Docker"' && open -a Docker
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v systemctl &> /dev/null; then
      sudo systemctl restart docker
    else
      echo "Systemd is not available. Please restart the Docker service manually."
      return 1
    fi
  else
    echo "Unsupported OS: $OSTYPE"
    return 1
  fi
}

# Restart a specific Docker container by name or ID.
docker_restart_container() {
  if [[ -z "$1" ]]; then
    echo "Usage: docker_restart_container <container_name_or_id>"
    return 1
  fi
  docker restart "$1"
}

# Remove all stopped containers.
docker_rm_stopped() {
  docker rm "$(docker ps -a -q -f status=exited)"
}

# Save a Docker image to a file.
docker_save() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: docker_save <image_name:tag> <output_file>"
    return 1
  fi
  docker save -o "$2" "$1"
}

# Stop and remove all Docker containers, images, and dangling volumes.
docker_wipe() {
  docker stop "$(docker ps -a -q)" &&
  docker rm "$(docker ps -a -q)" &&
  docker rmi "$(docker images -q)" &&
  docker volume rm "$(docker volume ls -qf dangling=true)"
}
