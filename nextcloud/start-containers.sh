#!/usr/bin/env bash
# Script to fix Nextcloud AIO 502 errors
# This happens when the master container is running but service containers are stopped

set -e

echo "Checking Nextcloud container status..."

# Check if master container is running
if ! docker ps --format "{{.Names}}" | grep -q "nextcloud-aio-mastercontainer"; then
    echo "❌ Error: Nextcloud AIO master container is not running!"
    echo "Please start it with: cd /home/connor/code/infra/nextcloud && docker compose up -d"
    exit 1
fi

echo "✓ Master container is running"

# Check which service containers are stopped
STOPPED_CONTAINERS=$(docker ps -a --filter "name=nextcloud-aio-" --format "{{.Names}}\t{{.Status}}" | grep "Exited" | awk '{print $1}' | grep -v "mastercontainer" | grep -v "borgbackup" | grep -v "domaincheck" || true)

if [ -z "$STOPPED_CONTAINERS" ]; then
    echo "✓ All Nextcloud service containers are already running"
    echo ""
    echo "Current status:"
    docker ps --filter "name=nextcloud-aio-" --format "table {{.Names}}\t{{.Status}}" | grep -v "borgbackup\|domaincheck"
    exit 0
fi

echo "⚠️  Found stopped containers:"
echo "$STOPPED_CONTAINERS"
echo ""
echo "Starting containers..."

# Start all service containers (excluding mastercontainer, borgbackup, domaincheck)
docker start nextcloud-aio-database nextcloud-aio-redis nextcloud-aio-nextcloud nextcloud-aio-apache nextcloud-aio-notify-push 2>/dev/null || true

echo "✓ Containers started"
echo ""
echo "Waiting for containers to initialize (15 seconds)..."
sleep 15

echo ""
echo "Container status:"
docker ps --filter "name=nextcloud-aio-" --format "table {{.Names}}\t{{.Status}}" | grep -v "borgbackup\|domaincheck"

echo ""
echo "Testing connection to Apache on port 11000..."
if curl -sI http://127.0.0.1:11000 >/dev/null 2>&1; then
    echo "✓ Apache is responding on port 11000"
    echo ""
    echo "Your Nextcloud should now be accessible at: https://nc.connorrhodes.com"
else
    echo "⚠️  Apache is not responding yet. Containers may still be starting up."
    echo "Check logs with: docker logs nextcloud-aio-apache"
fi
