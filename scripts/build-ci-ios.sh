#!/bin/bash
# MiaoYan iOS CI Build Script
#
# Purpose: produce an unsigned, ad-hoc signed IPA on a headless
# GitHub Actions macOS runner.
#
# Output: ./build/dist/MiaoYanMobile_V{version}.ipa

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Auto-detect version from project.pbxproj
VERSION=$(grep "MARKETING_VERSION" MiaoYan.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
[ "${1:-}" != "" ] && VERSION="$1"

if [ -z "$VERSION" ]; then
    echo -e "${RED}ERROR: Could not detect version${NC}"
    exit 1
fi

echo ""
echo "Building MiaoYan v$VERSION for iOS (CI, unsigned)"
echo "=================================================="

# 1. Clean
echo "[1/5] Cleaning..."
rm -rf ./build
xcodebuild clean -scheme MiaoYanMobile -configuration Release 2>/dev/null || true

# 2. Archive (no signing)
echo "[2/5] Archiving for iOS..."
xcodebuild archive \
    -scheme MiaoYanMobile \
    -configuration Release \
    -sdk iphoneos \
    -archivePath "./build/MiaoYanMobile.xcarchive" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

[ ! -d "./build/MiaoYanMobile.xcarchive" ] && echo -e "${RED}ERROR: Archive failed${NC}" && exit 1

# 3. Ad-hoc sign
echo "[3/5] Ad-hoc signing..."
xattr -cr "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app"
codesign --force --deep -s - "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app"

codesign -v "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Signature verification failed, continuing anyway...${NC}"
}

# 4. Create IPA
echo "[4/5] Creating IPA..."
IPA_NAME="MiaoYanMobile_V${VERSION}.ipa"
DIST_DIR="./build/dist"

mkdir -p "./build/Payload"
cp -R "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app" "./build/Payload/"
cd ./build && zip -r -q "../${IPA_NAME}" Payload && cd ..
rm -rf "./build/Payload"

xattr -cr "./${IPA_NAME}"

# 5. Move to dist/
echo "[5/5] Collecting artifacts..."
mkdir -p "$DIST_DIR"
mv "./${IPA_NAME}" "$DIST_DIR/"

echo ""
echo -e "${GREEN}MiaoYan v$VERSION iOS CI build succeeded!${NC}"
ls -lh "$DIST_DIR"
echo ""
