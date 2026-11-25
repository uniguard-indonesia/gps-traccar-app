#!/usr/bin/env bash
# Builds the release APK, app bundle and/or iOS archive and names the files
# after the version in pubspec.yaml, e.g. dist/uniguard-gps-1.0.0+2.aab.
#
#   tool/build_release.sh          # APK and app bundle (Android)
#   tool/build_release.sh apk      # just the APK
#   tool/build_release.sh aab      # just the app bundle
#   tool/build_release.sh ipa      # the iOS archive (macOS with Xcode only)
#   tool/build_release.sh all      # all three
#   tool/build_release.sh clean    # delete dist/ (only dist/, not build/)
#
# Flutter always writes app-release.apk / app-release.aab and an .ipa named
# after the Xcode product; the build expects those names, so the files are
# copied, not renamed in place. The number after the + is the Android version
# code and the iOS build number, which both stores want to rise on every
# upload.
set -euo pipefail
cd "$(dirname "$0")/.."

what="${1:-both}"
case "$what" in
  apk | aab | ipa | both | all | clean) ;;
  *) echo "usage: $0 [apk|aab|ipa|both|all|clean]" >&2; exit 64 ;;
esac

if [[ "$what" == clean ]]; then
  if [[ -d dist ]]; then
    du -sh dist | cut -f1 | xargs -I{} echo "removing dist/ ({})"
    rm -rf dist
  else
    echo "no dist/ to remove"
  fi
  exit 0
fi

version="$(sed -n 's/^version: *//p' pubspec.yaml | head -n 1 | tr -d '[:space:]')"
if [[ -z "$version" ]]; then
  echo "no version: in pubspec.yaml" >&2
  exit 1
fi
name="uniguard-gps-$version"
mkdir -p dist

if [[ "$what" == apk || "$what" == both || "$what" == all ]]; then
  flutter build apk --release
  cp build/app/outputs/flutter-apk/app-release.apk "dist/$name.apk"
  echo "dist/$name.apk"
fi
if [[ "$what" == aab || "$what" == both || "$what" == all ]]; then
  flutter build appbundle --release
  cp build/app/outputs/bundle/release/app-release.aab "dist/$name.aab"
  echo "dist/$name.aab"
fi
if [[ "$what" == ipa || "$what" == all ]]; then
  rm -rf build/ios/ipa
  flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
  ipa="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' | head -n 1)"
  if [[ -z "$ipa" ]]; then
    echo "flutter built no .ipa (is the signing set up in Xcode?)" >&2
    exit 1
  fi
  cp "$ipa" "dist/$name.ipa"
  echo "dist/$name.ipa"
fi
