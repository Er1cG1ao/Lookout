#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
destination="${1:-dist}"
version=$(python3 -c 'import plistlib; print(plistlib.load(open("Info.plist", "rb"))["CFBundleShortVersionString"])')
stage="build/Lookout-${version}"
mkdir -p "$destination" "$stage"
ditto --norsrc --noextattr build/Lookout.app "$stage/Lookout.app"
cp README.md README.zh-CN.md "$stage/"
mkdir -p "$stage/Docs" "$stage/Assets"
cp Docs/*.md "$stage/Docs/"
cp Assets/AppIcon.png "$stage/Assets/"
python3 - "$stage" "$version" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
root = Path.cwd()
stage, version = sys.argv[1:]
folders = ['Sources', 'Support', 'Tests', 'Docs', 'Assets', '.github']
files = ['README.md', 'README.zh-CN.md', 'CHANGELOG.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md',
         '.gitignore', 'Info.plist', 'build.sh', 'test.sh', 'package.sh', 'package-dmg.sh']
paths = [root / name for name in files]
for folder in folders:
    paths.extend(p for p in (root / folder).rglob('*') if p.is_file() and p.name != '.DS_Store')
with ZipFile(root / stage / f'Lookout-{version}-source.zip', 'w', ZIP_DEFLATED) as archive:
    for item in sorted(paths):
        if item.is_file(): archive.write(item, Path('Lookout') / item.relative_to(root))
PY
xattr -cr "$stage/Lookout.app"
codesign --verify --strict "$stage/Lookout.app"
ditto -c -k --keepParent --norsrc --noextattr "$stage" "$destination/Lookout-${version}-mac-arm64.zip"
