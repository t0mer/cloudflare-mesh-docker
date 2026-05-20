#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Starting Cloudflare WARP Connector container..."

if [ -z "${CF_WARP_CONNECTOR_TOKEN:-}" ]; then
  echo "[ERROR] CF_WARP_CONNECTOR_TOKEN environment variable is required."
  exit 1
fi

echo "[INFO] Enabling IP forwarding where supported..."

sysctl -w net.ipv4.ip_forward=1 || true
sysctl -w net.ipv6.conf.all.forwarding=1 || true
sysctl -w net.ipv6.conf.all.accept_ra=2 || true

echo "[INFO] Starting warp-svc..."

warp-svc > /var/log/warp-svc.log 2>&1 &
WARP_SVC_PID=$!

echo "[INFO] Waiting for warp-svc to become ready..."

for i in $(seq 1 30); do
  if warp-cli --accept-tos status >/dev/null 2>&1; then
    echo "[INFO] warp-svc is ready."
    break
  fi

  if [ "$i" -eq 30 ]; then
    echo "[ERROR] warp-svc did not become ready."
    cat /var/log/warp-svc.log || true
    exit 1
  fi

  sleep 2
done

echo "[INFO] Checking registration status..."

if warp-cli --accept-tos status 2>/dev/null | grep -qi "Registration Missing"; then
  echo "[INFO] Registering Cloudflare WARP connector..."
  warp-cli --accept-tos connector new "${CF_WARP_CONNECTOR_TOKEN}"
else
  echo "[INFO] WARP already appears to be registered."
fi

echo "[INFO] Connecting WARP..."

warp-cli --accept-tos connect || {
  echo "[ERROR] Failed to connect WARP."
  warp-cli --accept-tos status || true
  cat /var/log/warp-svc.log || true
  exit 1
}

echo "[INFO] WARP status:"
warp-cli --accept-tos status || true

echo "[INFO] Cloudflare WARP Connector is running."

tail -F /var/log/warp-svc.log &
wait "${WARP_SVC_PID}"
