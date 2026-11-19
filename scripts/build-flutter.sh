#!/bin/bash
# Flutter 项目构建 + 打包成无签名 IPA
# 用法: bash build-flutter.sh <项目目录> <产物名>
set -e

DIR="$1"
NAME="${2:-app}"
cd "$DIR"

echo "===== 环境信息 ====="
flutter --version

echo "===== 拉依赖 ====="
flutter pub get

echo "===== 编译（无签名）====="
flutter build ipa --no-codesign --release

echo "===== 定位产物 ====="
ARCHIVE=$(find build/ios/archive -maxdepth 1 -name '*.xcarchive' | head -n 1)
if [ -z "$ARCHIVE" ]; then
  echo "ERROR: 找不到 .xcarchive，编译可能失败了"
  exit 1
fi
echo "archive: $ARCHIVE"

APP=$(find "$ARCHIVE/Products/Applications" -maxdepth 1 -name '*.app' | head -n 1)
if [ -z "$APP" ]; then
  echo "ERROR: .xcarchive 里没有 .app"
  exit 1
fi
echo "app: $APP"

echo "===== 打包 IPA ====="
WORK="$RUNNER_TEMP/pkg"
rm -rf "$WORK"
mkdir -p "$WORK/Payload"
cp -R "$APP" "$WORK/Payload/"

cd "$WORK"
zip -qry "$GITHUB_WORKSPACE/${NAME}-unsigned.ipa" Payload
cd "$GITHUB_WORKSPACE"

ls -lh "${NAME}-unsigned.ipa"
shasum -a 256 "${NAME}-unsigned.ipa"
echo "DONE"
