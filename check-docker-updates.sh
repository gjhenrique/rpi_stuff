#!/bin/bash

# Script to check for newer Docker image versions
# Usage: ./check-docker-updates.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to get latest tag from Docker Hub
get_latest_tag_dockerhub() {
    local image=$1
    local repo=$(echo $image | cut -d'/' -f2- | cut -d':' -f1)

    # Try to get latest tag from Docker Hub API
    local response=$(curl -s "https://registry.hub.docker.com/v2/repositories/${repo}/tags?page_size=100" 2>/dev/null || echo "")

    if [ -n "$response" ]; then
        # Extract the latest non-latest tag (prefer stable versions)
        echo "$response" | grep -o '"name":"[^"]*"' | head -20 | sed 's/"name":"//g' | sed 's/"//g' | grep -v "^latest$" | grep -v "rc" | grep -v "beta" | grep -v "alpha" | head -1
    else
        echo "unknown"
    fi
}

# Function to get latest tag from GHCR
get_latest_tag_ghcr() {
    local image=$1
    local repo=$(echo $image | cut -d'/' -f2- | cut -d':' -f1)

    # GHCR API endpoint
    local response=$(curl -s "https://api.github.com/orgs/${repo%%/*}/packages/container/${repo#*/}/versions" 2>/dev/null || echo "")

    if [ -n "$response" ]; then
        echo "$response" | grep -o '"name":"[^"]*"' | head -5 | sed 's/"name":"//g' | sed 's/"//g' | head -1
    else
        echo "unknown"
    fi
}

# Function to check image version
check_image() {
    local image_full=$1
    local current_tag=$(echo $image_full | cut -d':' -f2)
    local image_name=$(echo $image_full | cut -d':' -f1)
    local registry=$(echo $image_name | cut -d'/' -f1)

    echo -e "\n${YELLOW}Checking: ${image_full}${NC}"
    echo "Current version: ${current_tag}"

    # Determine registry and get latest tag
    local latest_tag=""
    if [[ $image_name == *"ghcr.io"* ]]; then
        latest_tag=$(get_latest_tag_ghcr "$image_name")
    elif [[ $image_name == *"lscr.io"* ]]; then
        # LinuxServer.io - check their API or Docker Hub equivalent
        local ls_repo=$(echo $image_name | sed 's|lscr.io/linuxserver/||')
        latest_tag=$(get_latest_tag_dockerhub "linuxserver/${ls_repo}")
    else
        # Default to Docker Hub
        latest_tag=$(get_latest_tag_dockerhub "$image_name")
    fi

    if [ "$latest_tag" != "unknown" ] && [ -n "$latest_tag" ]; then
        if [ "$latest_tag" != "$current_tag" ]; then
            echo -e "${GREEN}✓ Newer version available: ${latest_tag}${NC}"
        else
            echo -e "${GREEN}✓ Already on latest version${NC}"
        fi
    else
        echo -e "${RED}✗ Could not determine latest version${NC}"
        echo "  Try checking manually: https://hub.docker.com/r/$(echo $image_name | sed 's|docker.io/||' | sed 's|lscr.io/linuxserver/|linuxserver/|')/tags" || true
    fi
}

# List of images from your compose files
images=(
    "lscr.io/linuxserver/jellyfin:10.10.7"
    "docker.io/linuxserver/transmission:4.0.6"
    "docker.io/linuxserver/jackett:0.22.2325"
    "docker.io/linuxserver/sonarr:4.0.15"
    "docker.io/linuxserver/radarr:5.27.5-nightly"
    "docker.io/linuxserver/kavita:0.8.7"
    "prom/prometheus:v3.6.0-rc.0"
    "grafana/grafana:11.5.2"
    "wywywywy/docker_stats_exporter:latest"
    "ghcr.io/home-operations/smartctl-exporter:0.14"
    "prom/alertmanager:v0.28.0"
    "ghcr.io/henrywhitaker3/adguard-exporter:latest"
    "ghcr.io/pedro-stanaka/qingping_exporter/exporter:v0.2.2"
    "billykwooten/openweather-exporter:latest"
    "lscr.io/linuxserver/syncthing:2.0.3"
    "lscr.io/linuxserver/plex:1.42.1"
    "lscr.io/linuxserver/emby:4.9.1-beta"
    "docker.io/tailscale/tailscale:v1.86.2"
    "docker.io/library/redis:8"
    "ghcr.io/paperless-ngx/paperless-ngx:2.18.1"
    "ghcr.io/servercontainers/samba:smbd-only-latest"
    "docker.io/photoprism/photoprism:preview"
    "docker.io/actualbudget/actual-server:25.8.0"
)

echo "=========================================="
echo "Docker Image Version Checker"
echo "=========================================="

for image in "${images[@]}"; do
    check_image "$image"
done

echo -e "\n${YELLOW}Note:${NC} This script provides approximate results."
echo "For accurate version checking, use the Docker commands below or check registry websites directly."
