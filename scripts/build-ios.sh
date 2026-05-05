#!/bin/bash
# MiaoYan iOS Build Script - Build unsigned IPA
#
# Usage:
#   ./build-ios.sh              - Build iOS IPA (auto-detect version)
#   ./build-ios.sh 1.2.3       - Build iOS IPA with version 1.2.3

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Auto-detect version from project.pbxproj
VERSION=$(grep "MARKETING_VERSION" MiaoYan.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
[ -n "$1" ] && VERSION="$1"

if [ -z "$VERSION" ]; then
    echo -e "${RED}ERROR: Could not detect version${NC}"
    exit 1
fi

echo ""
echo "Building MiaoYan v$VERSION for iOS (unsigned)"
echo "============================================="

# 1. Clean
echo "[1/5] Cleaning..."
rm -rf ./build
xcodebuild clean -scheme MiaoYanMobile -configuration Release 2>/dev/null || true

# 2. Archive
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

# Verify signature (warning only)
codesign -v "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Signature verification failed, continuing anyway...${NC}"
}

# 4. Create IPA
echo "[4/5] Creating IPA..."
IPA_NAME="MiaoYanMobile_V${VERSION}.ipa"
mkdir -p "./build/Payload"
cp -R "./build/MiaoYanMobile.xcarchive/Products/Applications/MiaoYanMobile.app" "./build/Payload/"
cd ./build && zip -r -q "../$IPA_NAME" Payload && cd ..
rm -rf "./build/Payload"

# 5. Move to Downloads
xattr -cr "./$IPA_NAME"
DOWNLOADS=~/Downloads
mv "./$IPA_NAME" "$DOWNLOADS/"

# Done
echo "[5/5] Done!"
echo ""
echo -e "${GREEN}MiaoYan v$VERSION iOS build succeeded!${NC}"
echo "  IPA: $DOWNLOADS/$IPA_NAME"
echo ""
echo -e "${YELLOW}Note: This is an ad-hoc signed IPA. To install on devices, you may need to re-sign with a valid provisioning profile.${NC}"
echo ""
