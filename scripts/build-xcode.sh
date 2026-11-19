#!/bin/bash
# 原生 Xcode / React Native 构建 + 打包成无签名 IPA
# 用法: bash build-xcode.sh <项目目录> <产物名> [scheme]
set -e

DIR="$1"
NAME="${2:-app}"
SCHEME_ARG="$3"
cd "$DIR"

echo "===== Xcode 版本 ====="
xcodebuild -version

if [ -f package.json ] && grep -q '"react-native"' package.json 2>/dev/null; then
  echo "===== React Native：安装依赖 ====="
  if [ -f yarn.lock ]; then yarn install --frozen-lockfile || yarn install
  else npm install --no-audit --no-fund; fi
fi

echo "===== CocoaPods ====="
if [ -f Podfile ]; then
  pod install --repo-update
elif [ -f ios/Podfile ]; then
  (cd ios && pod install --repo-update)
fi

if ls -d *.xcworkspace >/dev/null 2>&1; then
  TARGET="-workspace $(ls -d *.xcworkspace | head -n 1)"
elif ls -d ios/*.xcworkspace >/dev/null 2>&1; then
  TARGET="-workspace $(ls -d ios/*.xcworkspace | head -n 1)"
elif ls -d *.xcodeproj >/dev/null 2>&1; then
  TARGET="-project $(ls -d *.xcodeproj | head -n 1)"
elif ls -d ios/*.xcodeproj >/dev/null 2>&1; then
  TARGET="-project $(ls -d ios/*.xcodeproj | head -n 1)"
else
  echo "ERROR: 找不到 .xcodeproj 或 .xcworkspace"
  exit 1
fi
echo "target: $TARGET"

if [ -n "$SCHEME_ARG" ]; then
  SCHEME="$SCHEME_ARG"
else
  BASE=$(echo "$TARGET" | sed 's/^-[a-z]* //; s/\.\(xcworkspace\|xcodeproj\)$//' | xargs basename)
  LIST=$(xcodebuild $TARGET -list 2>/dev/null)
  if echo "$LIST" | sed -n '/Schemes:/,$p' | grep -qw "$BASE"; then
    SCHEME="$BASE"
  else
    SCHEME=$(echo "$LIST" | sed -n '/Schemes:/,$p' | tail -n +2 | awk 'NF{print $1; exit}')
  fi
fi

if [ -z "$SCHEME" ]; then
  echo "ERROR: 无法确定 scheme"
  xcodebuild $TARGET -list
  exit 1
fi
echo "scheme: $SCHEME"

echo "===== 归档（无签名）====="
set -o pipefail
xcodebuild archive \
  $TARGET \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$RUNNER_TEMP/App.xcarchive" \
  -derivedDataPath "$RUNNER_TEMP/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" \
  EXPANDED_CODE_SIGN_IDENTITY="" 2>&1 | tail -n 80

echo "===== 打包 IPA ====="
APP=$(find "$RUNNER_TEMP/App.xcarchive/Products/Applications" -maxdepth 1 -name '*.app' | head -n 1)
if [ -z "$APP" ]; then echo "ERROR: 归档里没有 .app"; exit 1; fi
echo "app: $APP"

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
