#!/bin/sh
set -eu

required="
Dockerfile
README.md
VERSION
LICENSE
NOTICE
compose.yaml
quadlet/cloudbot.container
rootfs/usr/local/bin/cloudbot-entrypoint
rootfs/usr/local/bin/cloudbot-healthcheck
scripts/smoke-test.sh
.github/workflows/container.yml
"

for f in $required; do
  test -s "$f"
done

version="$(cat VERSION)"
printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
test -s "docs/releases/v${version}.md"

grep -F 'USER 1000:1000' Dockerfile >/dev/null
grep -F 'VOLUME ["/data"]' Dockerfile >/dev/null
grep -F 'CLOUDBOT_VERSION=1.4.0' Dockerfile >/dev/null
grep -F 'd891d49254d5c95ddd997c0d44e03a502966ba34' Dockerfile >/dev/null
grep -F "ghcr.io/ploos-as/cloudbot:${version}" compose.yaml >/dev/null
grep -F "Image=ghcr.io/ploos-as/cloudbot:${version}" quadlet/cloudbot.container >/dev/null
grep -F 'linux/amd64,linux/arm64' .github/workflows/container.yml >/dev/null
grep -F 'gh release create' .github/workflows/container.yml >/dev/null
grep -F 'value=latest' .github/workflows/container.yml >/dev/null
grep -F "ghcr.io/ploos-as/cloudbot:${version}" "docs/releases/v${version}.md" >/dev/null

sh -n rootfs/usr/local/bin/cloudbot-entrypoint
sh -n rootfs/usr/local/bin/cloudbot-healthcheck
sh -n scripts/smoke-test.sh

if command -v docker >/dev/null 2>&1; then
  docker compose config >/dev/null
fi

echo "static validation: PASS"
