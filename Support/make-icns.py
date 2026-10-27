#!/usr/bin/env python3
"""Package standard PNG icon representations in an ICNS container."""
from pathlib import Path
import struct
import sys

source, output = map(Path, sys.argv[1:])
representations = [
    (b"icp4", "icon_16x16.png"),
    (b"icp5", "icon_32x32.png"),
    (b"icp6", "icon_32x32@2x.png"),
    (b"ic07", "icon_128x128.png"),
    (b"ic08", "icon_256x256.png"),
    (b"ic09", "icon_512x512.png"),
    (b"ic10", "icon_512x512@2x.png"),
]
chunks = []
for tag, name in representations:
    png = (source / name).read_bytes()
    assert png.startswith(b"\x89PNG\r\n\x1a\n")
    chunks.append(tag + struct.pack(">I", len(png) + 8) + png)
body = b"".join(chunks)
output.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
