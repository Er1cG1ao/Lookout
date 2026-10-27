#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/module-cache
xcrun swiftc -swift-version 5 -module-cache-path build/module-cache \
  Sources/AttentionPolicy.swift Tests/main.swift -o build/policy-tests
build/policy-tests
