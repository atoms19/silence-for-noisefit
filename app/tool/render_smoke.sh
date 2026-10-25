#!/usr/bin/env bash
# Run from app/. First argument is a writable, populated Linux Flutter SDK.
set -euo pipefail
silence_sdk="${1:-${FLUTTER_ROOT:-}}"
if [[ -z "$silence_sdk" ]]; then
  echo 'Usage: bash tool/render_smoke.sh /path/to/flutter-sdk' >&2
  exit 2
fi
export FLUTTER_ROOT="$silence_sdk"
export DART_SUPPRESS_ANALYTICS=true
export FLUTTER_SUPPRESS_ANALYTICS=true
"$silence_sdk/bin/cache/dart-sdk/bin/dart" \
  "$silence_sdk/bin/cache/flutter_tools.snapshot" \
  --suppress-analytics --no-version-check build bundle --no-pub \
  --debug --target tool/render_smoke.dart
"$silence_sdk/bin/cache/artifacts/engine/linux-x64/flutter_tester" \
  --disable-vm-service --enable-software-rendering --non-interactive --run-forever \
  --flutter-assets-dir=build/flutter_assets build/flutter_assets/kernel_blob.bin
