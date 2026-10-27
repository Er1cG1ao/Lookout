#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
destination="${1:-dist}"
version=$(python3 -c 'import plistlib; print(plistlib.load(open("Info.plist", "rb"))["CFBundleShortVersionString"])')
stage=$(mktemp -d "${TMPDIR:-/tmp}/lookout-dmg.XXXXXX")
trap 'rm -rf "$stage"' EXIT
mkdir -p "$destination"
ditto --norsrc --noextattr build/Lookout.app "$stage/Lookout.app"
ln -s /Applications "$stage/Applications"
cat > "$stage/Install.txt" <<'TEXT'
Drag Lookout.app into Applications. Quit the old version before replacing it.
Apple Silicon, macOS 14 or later. Open and allow Camera access, then calibrate.
This prototype is ad hoc signed, not notarized. If blocked, allow it in Privacy & Security.
Lookout does not recognize identity or replace the system lock screen.

将 Lookout.app 拖入 Applications（应用程序）；升级前先退出旧版。
需要 Apple Silicon、macOS 14+。打开后允许摄像头权限，再校准正常坐姿。
原型使用本机临时签名、未经公证；如被拦截可在「隐私与安全性」中允许打开。
不识别身份，不替代系统锁屏。
TEXT
xattr -cr "$stage/Lookout.app"
codesign --verify --strict "$stage/Lookout.app"
hdiutil create -volname Lookout -srcfolder "$stage" -ov -format UDZO "$destination/Lookout-${version}-mac-arm64.dmg"
hdiutil verify "$destination/Lookout-${version}-mac-arm64.dmg"
