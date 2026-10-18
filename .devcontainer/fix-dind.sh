#!/bin/bash
set -euo pipefail

TARGET_CONTAINERD="2.2.3-debian12u1"
CURRENT_CONTAINERD="$(dpkg-query -W -f='${Version}' moby-containerd 2>/dev/null || echo none)"

if [ "$CURRENT_CONTAINERD" != "$TARGET_CONTAINERD" ]; then
  echo "Pinning moby-containerd to ${TARGET_CONTAINERD} (was ${CURRENT_CONTAINERD})"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades "moby-containerd=${TARGET_CONTAINERD}"
  apt-mark hold moby-containerd
fi

if docker info >/dev/null 2>&1; then
  echo "Docker daemon is running"
  exit 0
fi

echo "Starting Docker daemon..."
pkill -9 dockerd 2>/dev/null || true
pkill -9 containerd 2>/dev/null || true
find /run /var/run -iname 'docker*.pid' -delete 2>/dev/null || true
find /run /var/run -iname 'container*.pid' -delete 2>/dev/null || true

nohup /usr/local/share/docker-init.sh true >> /tmp/docker-init.log 2>&1 &

for _ in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    echo "Docker daemon started"
    exit 0
  fi
  sleep 1
done

echo "Docker failed to start; see /tmp/dockerd.log and /tmp/docker-init.log" >&2
exit 1
