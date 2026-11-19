#!/bin/sh
# 自动判断项目类型，输出 flutter / rn / xcode / unknown
# 用法: sh detect.sh <项目根目录>

DIR="${1:-.}"
cd "$DIR" || { echo "unknown"; exit 0; }

if [ -f pubspec.yaml ] && [ -d lib ] && grep -qE '^[[:space:]]*flutter:' pubspec.yaml; then
  echo "flutter"; exit 0
fi

if [ -f package.json ] && grep -q '"react-native"' package.json 2>/dev/null; then
  echo "rn"; exit 0
fi

if ls -d *.xcworkspace *.xcodeproj >/dev/null 2>&1; then
  echo "xcode"; exit 0
fi

if [ -d ios ]; then
  if ls -d ios/*.xcworkspace ios/*.xcodeproj >/dev/null 2>&1; then
    echo "xcode"; exit 0
  fi
fi

FOUND=$(find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) -not -path '*/Pods/*' | head -n 1)
if [ -n "$FOUND" ]; then echo "xcode"; exit 0; fi

echo "unknown"
