# CloudBot container

Production-oriented OCI image for [CloudBot](https://github.com/TotallyNotRobots/CloudBot), packaged by Ploos AS.

## Image

`ghcr.io/ploos-as/cloudbot:edge`

Initial packaging pin:

- CloudBot 1.4.0
- upstream commit `d891d49254d5c95ddd997c0d44e03a502966ba34`
- Python 3.11 slim-bookworm
- Linux amd64 + arm64
- non-root UID/GID 1000
- persistent state/config under `/data`
- tini as PID 1
- Docker Compose + Podman Quadlet
- SBOM + provenance on published images

## Quick start

Prepare writable state:

```sh
mkdir -p data
sudo chown 1000:1000 data
```

Create a starter config:

```sh
docker run --rm -v "$PWD/data:/data" ghcr.io/ploos-as/cloudbot:edge init
```

Edit `data/config.json`, then run:

```sh
docker run -d --name cloudbot \
  --restart unless-stopped \
  -v "$PWD/data:/data" \
  ghcr.io/ploos-as/cloudbot:edge
```

With Compose:

```sh
docker compose up -d
```

## Configuration

The container expects `/data/config.json` by default. Set `CLOUDBOT_CONFIG` to select another JSON file inside `/data`, or an absolute path.

If no config exists, the container does not crash-loop; it prints setup instructions and remains idle. Its healthcheck intentionally stays unhealthy until CloudBot is actually running.

`init` copies CloudBot's upstream `config.default.json` to the selected config path without overwriting an existing file.

## Persistence

Mount `/data`. The container runs as UID/GID 1000, so bind-mounted directories must be writable by that user.

## Upstream and licensing

CloudBot is GPL-3.0-or-later. The pinned upstream source is retained in the image at `/usr/src/cloudbot`. See `NOTICE` and `LICENSE`.

Ploos AS is not affiliated with the CloudBot maintainers.
