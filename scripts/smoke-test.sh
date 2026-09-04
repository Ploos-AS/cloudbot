#!/bin/sh
set -eu

image="${1:-cloudbot:test}"
name="cloudbot-smoke-$$"
tmp="$(mktemp -d)"

cleanup() {
  status=$?
  echo "smoke cleanup: status=$status"
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run --rm --user 0:0 -v "$tmp:/cleanup" --entrypoint /bin/sh "$image" -c 'rm -rf /cleanup/* /cleanup/.[!.]* /cleanup/..?* 2>/dev/null || true' >/dev/null 2>&1 || true
  rm -rf "$tmp" || true
  exit "$status"
}
trap cleanup EXIT INT TERM

fail() {
  echo "smoke test: FAIL: $*" >&2
  echo "--- container inspect ---" >&2
  docker inspect "$name" 2>/dev/null || true
  echo "--- container logs ---" >&2
  docker logs "$name" 2>/dev/null || true
  echo "--- data tree ---" >&2
  docker run --rm --user 0:0 -v "$tmp:/data" --entrypoint /bin/sh "$image" -c 'find /data -maxdepth 3 -printf "%M %u:%g %p\n" 2>/dev/null | sort' >&2 || true
  exit 1
}

chmod 0777 "$tmp"

echo "smoke: checking runtime UID/GID"
uid="$(docker run --rm --entrypoint id "$image" -u)"
gid="$(docker run --rm --entrypoint id "$image" -g)"
[ "$uid" = "1000" ] || fail "expected UID 1000, got $uid"
[ "$gid" = "1000" ] || fail "expected GID 1000, got $gid"

echo "smoke: checking CloudBot import from default working directory"
docker run --rm --entrypoint python "$image" -c 'import cloudbot; print(cloudbot.__file__)' || fail "CloudBot import failed"

echo "smoke: creating starter configuration"
docker run --rm -v "$tmp:/data" "$image" init || fail "init command failed"
[ -s "$tmp/config.json" ] || fail "init did not create non-empty config.json"

echo "smoke: starting configured container"
docker run -d --name "$name" -v "$tmp:/data" "$image" >/dev/null || fail "docker run failed"
sleep 5

running="$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)"
exit_code="$(docker inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null || true)"
health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name" 2>/dev/null || true)"
echo "smoke: running=$running exit_code=$exit_code health=$health"

[ "$running" = "true" ] || fail "container exited (exit_code=$exit_code)"

if [ "$health" = "unhealthy" ]; then
  fail "container became unhealthy"
fi

echo "smoke test: PASS"
