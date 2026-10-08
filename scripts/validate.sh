#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCAN_ROOT=${DEV_BRAIN_SCAN_ROOT:-$ROOT}
ALLOWLIST=${DEV_BRAIN_ALLOWLIST_FILE:-$ROOT/security/secret-scan-allowlist.txt}
private_key_pattern='BEGIN PRIVATE'' KEY'

echo '检查内容契约'
sh "$ROOT/tests/test-content.sh"

hash_file() {
  file=$1
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    sha256sum "$file" | awk '{print $1}'
  fi
}

relative_path() {
  file=$1
  case "$SCAN_ROOT" in
    "$ROOT") printf '%s\n' "${file#"$ROOT"/}" ;;
    *) printf '%s\n' "${file#"$SCAN_ROOT"/}" ;;
  esac
}

allowlisted() {
  file=$1
  rel=$2
  [ -f "$ALLOWLIST" ] || return 1
  actual=$(hash_file "$file")
  while IFS=' ' read -r kind expected expected_path rest; do
    case "${kind:-}" in
      ''|'#') continue ;;
      sha256) [ -z "${rest:-}" ] || return 1 ;;
      *) return 1 ;;
    esac
    case "$expected_path" in
      *\**|*\?*) return 1 ;;
    esac
    if [ "$expected" = "$actual" ] && [ "$expected_path" = "$rel" ]; then
      return 0
    fi
  done < "$ALLOWLIST"
  return 1
}

report_match() {
  file=$1
  rel=$2
  pattern=$3
  if allowlisted "$file" "$rel"; then
    return 0
  fi
  echo "敏感信息或本机信息命中: $rel ($pattern)" >&2
  return 1
}

scan_file() {
  file=$1
  rel=$(relative_path "$file")
  failed=0

  case "$(basename "$file")" in
    .env|.env.*)
      [ "$(basename "$file")" = '.env.example' ] || {
        echo "环境文件不应进入知识库: $rel" >&2
        failed=1
      }
      ;;
  esac

  if grep -Iq . "$file" 2>/dev/null; then
    if grep -nE -- "$private_key_pattern" "$file" >/dev/null 2>&1; then
      report_match "$file" "$rel" 'private-key' || failed=1
    fi
    if grep -nE -- 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}' "$file" >/dev/null 2>&1; then
      report_match "$file" "$rel" 'token' || failed=1
    fi
    if grep -nE -- '/Users/[A-Za-z0-9._-]+/|C:[\\\\]Users[\\\\][A-Za-z0-9._-]+[\\\\]' "$file" >/dev/null 2>&1; then
      echo "本机绝对路径不应进入知识库: $rel" >&2
      failed=1
    fi
  fi
  return "$failed"
}

failed=0
if [ "$SCAN_ROOT" = "$ROOT" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    scan_file "$ROOT/$rel" || failed=1
  done <<EOF
$(git -C "$ROOT" ls-files --cached --others --exclude-standard)
EOF
else
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    scan_file "$file" || failed=1
  done <<EOF
$(find "$SCAN_ROOT" -type f -print)
EOF
fi

[ "$failed" -eq 0 ] || exit 1
echo '敏感信息和内容校验通过'
