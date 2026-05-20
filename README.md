# cloudflare-mesh-docker

Runs the Cloudflare WARP Connector inside a Docker container instead of installing it directly on the host OS.

## Security

The connector token is never baked into the image. It must be passed at runtime via the `CF_WARP_CONNECTOR_TOKEN` environment variable.

## Quick start

### Docker run

```bash
docker run -d \
  --name cloudflare-mesh \
  --restart unless-stopped \
  --privileged \
  --network host \
  -e CF_WARP_CONNECTOR_TOKEN="TOKEN_HERE" \
  techblog/cloudflare-mesh:latest
```

### Docker Compose

```yaml
services:
  cloudflare-mesh:
    image: techblog/cloudflare-mesh:latest
    container_name: cloudflare-mesh
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      CF_WARP_CONNECTOR_TOKEN: "${CF_WARP_CONNECTOR_TOKEN}"
    volumes:
      - cloudflare-warp-data:/var/lib/cloudflare-warp

volumes:
  cloudflare-warp-data:
```

```bash
export CF_WARP_CONNECTOR_TOKEN="TOKEN_HERE"
docker compose up -d
```

## Permissions

The container requires elevated permissions because WARP creates network interfaces and modifies routing:

- `--privileged` — grants full host capabilities
- `--network host` — required for the connector to function as a network node

An alternative with explicit capabilities may also work:

```bash
--cap-add NET_ADMIN \
--cap-add SYS_MODULE \
--device /dev/net/tun
```

## Persistence

Mount `/var/lib/cloudflare-warp` as a volume (shown in the Compose example above) so that WARP registration is preserved across container restarts.

## Troubleshooting

```bash
# Stream container logs
docker logs -f cloudflare-mesh

# Check WARP status
docker exec -it cloudflare-mesh warp-cli status

# Check tunnel stats
docker exec -it cloudflare-mesh warp-cli tunnel stats

# Inspect routing table
docker exec -it cloudflare-mesh ip route

# Inspect network interfaces
docker exec -it cloudflare-mesh ip addr
```

## Building locally

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t techblog/cloudflare-mesh:latest .
```

## GitHub Actions

The workflow at `.github/workflows/docker-build.yml` builds and pushes a multi-arch image (`linux/amd64`, `linux/arm64`) to DockerHub on manual trigger (`workflow_dispatch`).

Required repository secrets:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | DockerHub account username |
| `DOCKERHUB_TOKEN` | DockerHub access token |
