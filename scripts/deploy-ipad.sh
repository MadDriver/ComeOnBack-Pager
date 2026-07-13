#!/bin/bash
# Build the pager (Release, device) and install it on a connected iPad via devicectl —
# no Xcode GUI, no TestFlight. Automatic signing (team 9XKN747L88) uses this Mac's dev
# cert; -allowProvisioningUpdates fetches/renews the provisioning profile on the fly.
#
# Usage: scripts/deploy-ipad.sh [device-name-or-udid]
#   No argument: list connected/paired devices, then re-run with one.
#   The iPad must be paired with this Mac (USB once, then Wi-Fi works).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -eq 0 ]; then
  echo "Connected devices (re-run with a name or UDID):"
  xcrun devicectl list devices
  exit 0
fi
DEVICE="$1"

xcodegen generate
xcodebuild -project "ComeOnBack Pager.xcodeproj" -scheme ComeOnBackPager \
  -destination generic/platform=iOS -configuration Release \
  -derivedDataPath build -allowProvisioningUpdates build

xcrun devicectl device install app --device "$DEVICE" \
  "build/Build/Products/Release-iphoneos/ComeOnBack Pager.app"
echo "Installed on $DEVICE."
