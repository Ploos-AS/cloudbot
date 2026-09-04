#!/bin/sh
set -eu
image="${1:-cloudbot:test}"
name="cloudbot-smoke-$$"
tmp="$(mktemp -d)"

cleanup() {
  docker rm -f "$name" >/dev/null 2>&1 || true
  if [ -d "$tmp" ]; then
    docker run --rm --entrypoint sh -v "$tmp:/cleanup" "$image" -c 'rm -rf /cleanup/* /cleanup/.[!.]* /cleanup/..?* 2>/dev/null || true' >/dev/null 2>&1 || true
    rm -rf "$tmp"
  fi
}
trap cleanup EXIT INT TERM

chmod 0777 "$tmp"

test "$(docker run --rm --entrypoint id "$image" -u)" = "1000"
test "$(docker run --rm --entrypoint id "$image" -g)" = "1000"

docker run --rm --entrypoint python "$image" -c 'import sys; sys.path.insert(0,"/usr/src/cloudbot"); import cloudbot' >/dev/null

docker run --rm -v "$tmp:/data" "$image" init >/dev/null
test -s "$tmp/config.json"

docker run -d --name "$name" -v "$tmp:/data" "$image" >/dev/null
sleep 5
docker inspect -f '{{.State.Running}}' "$name" | grep -Fx true >/dev/null

echo "smoke test: PASS"
