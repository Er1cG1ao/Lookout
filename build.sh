#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/module-cache build/Lookout.app/Contents/MacOS build/Lookout.app/Contents/Resources
xcrun swiftc -O -swift-version 5 -target arm64-apple-macosx14.0 \
  -module-cache-path build/module-cache Sources/*.swift \
  -framework AppKit -framework SwiftUI -framework AVFoundation -framework Vision \
  -framework CoreImage -framework Combine -o build/Lookout.app/Contents/MacOS/Lookout
cp Info.plist build/Lookout.app/Contents/Info.plist
xcrun swift -module-cache-path build/module-cache Support/make-icon.swift build/Lookout.iconset
python3 Support/make-icns.py build/Lookout.iconset build/Lookout.app/Contents/Resources/Lookout.icns
cp LICENSE THIRD_PARTY_NOTICES.md build/Lookout.app/Contents/Resources/
xattr -cr build/Lookout.app
codesign --force --sign - build/Lookout.app
codesign --verify --strict build/Lookout.app
echo "Built: $(pwd)/build/Lookout.app"
