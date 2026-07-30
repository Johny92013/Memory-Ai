#!/usr/bin/env bash
# Baut IPA 1.0.0+1 auf macOS.
# Usage:
#   ./tool/build_ios_ipa_macos.sh              # unsigned (Sideloadly)
#   ./tool/build_ios_ipa_macos.sh signed development
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="1.0.0"
BUILD="1"
MODE="${1:-unsigned}"
EXPORT_METHOD="${2:-development}"
OUT_DIR="release/${VERSION}"
mkdir -p "$OUT_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "FEHLER: Dieses Script läuft nur auf macOS mit Xcode."
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "FEHLER: .env fehlt (SUPABASE_URL + SUPABASE_PUBLISHABLE_KEY)."
  exit 1
fi

flutter clean
flutter pub get
(
  cd ios
  pod install
)
dart format .
flutter analyze
flutter test

if [[ "$MODE" == "unsigned" ]]; then
  flutter build ios --release --no-codesign \
    --build-name="$VERSION" --build-number="$BUILD"

  APP_PATH="$(find build/ios/iphoneos -name '*.app' -maxdepth 1 | head -n 1)"
  if [[ -z "$APP_PATH" ]]; then
    echo "FEHLER: .app nicht gefunden."
    exit 1
  fi

  rm -rf Payload
  mkdir Payload
  cp -R "$APP_PATH" Payload/
  IPA_PATH="${OUT_DIR}/MemoryAI-${VERSION}+${BUILD}-unsigned.ipa"
  rm -f "$IPA_PATH"
  zip -r "$IPA_PATH" Payload
  rm -rf Payload
  echo "IPA erstellt: $IPA_PATH"
  echo "In Sideloadly öffnen und mit Apple-ID signieren/installieren."
  exit 0
fi

case "$EXPORT_METHOD" in
  development) PLIST="ios/ExportOptions-development.plist" ;;
  ad-hoc) PLIST="ios/ExportOptions-ad-hoc.plist" ;;
  app-store) PLIST="ios/ExportOptions-app-store.plist" ;;
  *)
    echo "Unbekannte Export-Methode: $EXPORT_METHOD"
    exit 1
    ;;
esac

if grep -q "YOUR_APPLE_TEAM_ID" "$PLIST"; then
  echo "FEHLER: teamID in $PLIST noch Platzhalter. Apple Team ID eintragen."
  exit 1
fi

flutter build ipa \
  --build-name="$VERSION" --build-number="$BUILD" \
  --export-options-plist="$PLIST"

BUILT="$(find build/ios/ipa -name '*.ipa' | head -n 1)"
if [[ -z "$BUILT" ]]; then
  echo "FEHLER: signierte IPA nicht gefunden."
  exit 1
fi

DEST="${OUT_DIR}/MemoryAI-${VERSION}+${BUILD}-signed.ipa"
cp "$BUILT" "$DEST"
echo "IPA erstellt: $DEST"
