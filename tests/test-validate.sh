#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$ROOT/scripts/validate.sh"

FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
printf '%s\n' '-----BEGIN PRIVATE'' KEY-----' > "$FIXTURE/leak.txt"
if DEV_BRAIN_SCAN_ROOT="$FIXTURE" sh "$ROOT/scripts/validate.sh"; then
  echo '敏感信息未被阻止' >&2
  exit 1
fi

mv "$FIXTURE/leak.txt" "$FIXTURE/allowed-test-key.txt"
if command -v shasum >/dev/null 2>&1; then
  HASH=$(shasum -a 256 "$FIXTURE/allowed-test-key.txt" | awk '{print $1}')
else
  HASH=$(sha256sum "$FIXTURE/allowed-test-key.txt" | awk '{print $1}')
fi
printf 'sha256 %s %s\n' "$HASH" 'allowed-test-key.txt' > "$FIXTURE/allowlist.txt"
DEV_BRAIN_SCAN_ROOT="$FIXTURE" DEV_BRAIN_ALLOWLIST_FILE="$FIXTURE/allowlist.txt" sh "$ROOT/scripts/validate.sh"

cp "$FIXTURE/allowed-test-key.txt" "$FIXTURE/same-secret-wrong-path.txt"
if DEV_BRAIN_SCAN_ROOT="$FIXTURE" DEV_BRAIN_ALLOWLIST_FILE="$FIXTURE/allowlist.txt" sh "$ROOT/scripts/validate.sh"; then
  echo '白名单错误放行了其他路径' >&2
  exit 1
fi
echo '校验器测试通过'
