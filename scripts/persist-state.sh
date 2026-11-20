#!/usr/bin/env bash
# Persist the runtime state under $STATE_DIR to the PRIVATE repository's
# test-state branch. Called periodically and once at the end of a run. The
# branch holds a snapshot, so it is replaced wholesale and force-pushed each
# time: that keeps repeated calls from being rejected as non-fast-forward.
set -euo pipefail

: "${STATE_DIR:?STATE_DIR is required}"
: "${PRIVATE_REPO:?PRIVATE_REPO is required}"
: "${PRIVATE_REPO_TOKEN:?PRIVATE_REPO_TOKEN is required}"

WORK="${RUNNER_TEMP:-/tmp}/la-state"
REMOTE="https://x-access-token:${PRIVATE_REPO_TOKEN}@github.com/${PRIVATE_REPO}.git"

rm -rf "$WORK"
mkdir -p "$WORK/defect-images"
git -C "$WORK" init -q
git -C "$WORK" remote add origin "$REMOTE"
git -C "$WORK" config user.name "github-actions[bot]"
git -C "$WORK" config user.email "41898282+github-actions[bot]@users.noreply.github.com"

copy_if() { if [ -f "$1" ]; then cp -f "$1" "$WORK/"; fi; }
copy_if "$STATE_DIR/accounts-state.json"
copy_if "$STATE_DIR/server-accounts.json"
copy_if "$STATE_DIR/platform.json"
copy_if "$STATE_DIR/launcher-users.json"
copy_if "$STATE_DIR/endpoint.txt"
copy_if "$STATE_DIR/gm-token.txt"
if [ -d "$STATE_DIR/defect-images" ]; then
  cp -f "$STATE_DIR"/defect-images/* "$WORK/defect-images/" 2>/dev/null || true
fi

git -C "$WORK" add -A
git -C "$WORK" commit -q -m "state: $(date -u +%Y-%m-%dT%H:%M:%SZ) 测试服存档"
git -C "$WORK" push -q --force origin HEAD:test-state
echo "[persist] 存档已推到 ${PRIVATE_REPO} 的 test-state 分支"
