#!/usr/bin/env bash
# One unauthenticated firmware-metadata check with isOTARequired=true.
# Only this flag differs from the baseline; results are saved separately.
# No retry, redirect or firmware download.
# version=26 is the candidate numeric suffix of reported 5.4.328.26.
# firmware_id=2109 is the APK default; MAC and account token are unavailable here.
set -u
check_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
curl --silent --show-error \
  --proto '=https' --connect-timeout 10 --max-time 30 --retry 0 \
  --request POST 'https://app-eks.gonoise.com/core/watch/firmware_versions' \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header 'version: 876' \
  --header 'version-name: 5.4.6' \
  --header 'platform: android' \
  --data-binary "@$check_dir/request.json" \
  --dump-header "$check_dir/response-headers.txt" \
  --output "$check_dir/response-body.txt" \
  --write-out '%{http_code}\n' > "$check_dir/http-status.txt" 2> "$check_dir/curl-stderr.txt"
check_exit=$?
printf '%s\n' "$check_exit" > "$check_dir/curl-exit-code.txt"
printf 'curl exit code: %s\nHTTP status: ' "$check_exit"
cat "$check_dir/http-status.txt"
if [ "$check_exit" -ne 0 ]; then
  cat "$check_dir/curl-stderr.txt"
else
  printf 'Response saved to %s/response-body.txt\n' "$check_dir"
fi
exit "$check_exit"
