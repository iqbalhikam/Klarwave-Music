#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

flutter create \
  --platforms=android,ios \
  --org com.klarwave \
  --project-name music \
  "$TMP_DIR/scaffold" >/dev/null

cp -R "$TMP_DIR/scaffold/android" .
cp -R "$TMP_DIR/scaffold/ios" .

cp platform_overrides/android/app/src/main/AndroidManifest.xml \
  android/app/src/main/AndroidManifest.xml

mkdir -p android/app/src/main/kotlin/com/klarwave/music
cp platform_overrides/android/app/src/main/kotlin/com/klarwave/music/MainActivity.kt \
  android/app/src/main/kotlin/com/klarwave/music/MainActivity.kt

cp platform_overrides/ios/Runner/Info.plist ios/Runner/Info.plist

echo "Folder android/ dan ios/ siap dipakai."
