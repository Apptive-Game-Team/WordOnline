#!/usr/bin/env bash
# Commit a version bump straight onto origin/main through the GitHub Contents
# API, so no local checkout, branch, or working tree is touched.
# Usage: bump-version.sh <owner/repo> <file> <kind> <old> <new>
set -euo pipefail

repo=$1 file=$2 kind=$3 old=$4 new=$5
case "$kind" in
  gradle) component=${repo##*/}; old_line="version = '$old'"; new_line="version = '$new'" ;;
  unity)  component=${repo##*/}; old_line="  bundleVersion: $old"; new_line="  bundleVersion: $new" ;;
  *) echo "unknown kind: $kind" >&2; exit 2 ;;
esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

gh api "repos/$repo/contents/$file?ref=main" > "$work/meta.json"
sha=$(jq -r .sha "$work/meta.json")
jq -r .content "$work/meta.json" | tr -d '\n' | base64 -d > "$work/old"

grep -Fxq "$old_line" "$work/old" || { echo "version line not found in $repo:$file: $old_line" >&2; exit 1; }
[ "$(grep -Fxc "$old_line" "$work/old")" = 1 ] || { echo "version line is ambiguous in $repo:$file" >&2; exit 1; }

awk -v old="$old_line" -v new="$new_line" '$0 == old { print new; next } { print }' "$work/old" > "$work/new"

changed=$(diff "$work/old" "$work/new" | grep -c '^[<>]' || true)
[ "$changed" = 2 ] || { echo "refusing to commit: $changed changed lines in $repo:$file" >&2; exit 1; }

jq -n \
  --arg message "chore(release): $component v$new" \
  --arg content "$(base64 -w0 "$work/new")" \
  --arg sha "$sha" \
  '{message: $message, content: $content, sha: $sha, branch: "main"}' \
  | gh api -X PUT "repos/$repo/contents/$file" --input - --jq '.commit.sha'
