# CloudBot container

Production-oriented OCI image for [CloudBot](https://github.com/TotallyNotRobots/CloudBot), packaged by Ploos AS.

## Image

Stable release:

`ghcr.io/ploos-as/cloudbot:0.1.0`

Development channel:

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
docker run --rm -v "$PWD/data:/data" ghcr.io/ploos-as/cloudbot:0.1.0 init
```

Edit `data/config.json`, then run:

```sh
docker run -d --name cloudbot \
  --restart unless-stopped \
  -v "$PWD/data:/data" \
  ghcr.io/ploos-as/cloudbot:0.1.0
```

With Compose:

```sh
docker compose up -d
```

## Configuration

The container expects `/data/config.json` by default. Set `CLOUDBOT_CONFIG` to select another JSON file inside `/data`, or an absolute path.

If no config exists, the container does not crash-loop; it prints setup instructions and remains idle. Its healthcheck intentionally stays unhealthy until CloudBot is actually running.

`init` copies CloudBot's upstream `config.default.json` to the selected config path without overwriting an existing file.

## Plugins and persistence

Mount `/data`. The container runs as UID/GID 1000, so bind-mounted directories must be writable by that user.

CloudBot expects plugin paths to live below its runtime base directory. On first configured start, the container therefore seeds the pinned built-in plugins into `/data/plugins` instead of symlinking them back into the read-only source tree. Existing files under `/data/plugins` are preserved, so the persistent directory can be customized independently of the image.

Runtime data and logs are kept under `/data/data` and `/data/logs`.

## Image lifecycle

`0.1.0`, `0.1`, and `latest` are release tags. `edge` follows successful builds from `main` and is intended for testing upcoming packaging changes.

Published multi-architecture images are built for `linux/amd64` and `linux/arm64`. Release builds request BuildKit provenance and SBOM attestations.

## Upstream and licensing

CloudBot is GPL-3.0-or-later. The pinned upstream source, including its license material, is retained in the image at `/usr/src/cloudbot`. See `NOTICE` and `LICENSE`.

Ploos AS is not affiliated with the CloudBot maintainers.
