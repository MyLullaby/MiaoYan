#!/bin/bash
# MiaoYan CI Build Script
#
# Purpose: produce an unsigned, ad-hoc signed MiaoYan.app + DMG + ZIP on a
# headless GitHub Actions macOS runner. This is a CI-only counterpart of
# scripts/build.sh — the local script is left untouched.
#
# Differences vs scripts/build.sh:
#   - No AppleScript / Finder layout step (runners are headless, Finder
#     cannot be driven, hdiutil convert ends up failing).
#   - No Sparkle sign_update step (no EdDSA private key in CI Keychain).
#   - Outputs go to ./build/dist/ (not ~/Downloads).

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

APP_NAME="MiaoYan"
DMG_NAME="MiaoYan.dmg"
DIST_DIR="./build/dist"
STAGING_DIR="./build/dmg_staging"
DMG_BASE_PATH="./build/${DMG_NAME%.dmg}"

echo ""
echo "Building MiaoYan v$VERSION (CI, unsigned)"
echo "=========================================="

# 1. Clean
echo "[1/5] Cleaning..."
rm -rf ./build
xcodebuild clean -scheme MiaoYan -configuration Release 2>/dev/null || true

# 2. Archive (no signing)
echo "[2/5] Archiving..."
xcodebuild archive \
	-scheme MiaoYan \
	-configuration Release \
	-archivePath "./build/MiaoYan.xcarchive" \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO

[ ! -d "./build/MiaoYan.xcarchive" ] && echo -e "${RED}ERROR: Archive failed${NC}" && exit 1

# 3. Export
echo "[3/5] Exporting..."
mkdir -p "./build/Release"
cp -R "./build/MiaoYan.xcarchive/Products/Applications/MiaoYan.app" "./build/Release/MiaoYan.app"

# 4. Ad-hoc sign & package (no Finder layout — CI is headless)
echo "[4/5] Ad-hoc signing & packaging..."
xattr -cr "./build/Release/MiaoYan.app"
if [ -d "./build/Release/MiaoYan.app/Contents/Frameworks" ]; then
	find "./build/Release/MiaoYan.app/Contents/Frameworks" -depth -name "*.framework" -print0 | xargs -0 codesign --force --deep -s -
fi
codesign --force --deep -s - "./build/Release/MiaoYan.app"
codesign -v "./build/Release/MiaoYan.app" || {
	echo -e "${RED}ERROR: Signature verification failed${NC}"
	exit 1
}

# ZIP — skipped on CI (DMG is the only artifact we need)

# DMG — plain drag-to-Applications layout, no AppleScript
rm -rf "$STAGING_DIR" "./build/$DMG_NAME"
mkdir -p "$STAGING_DIR"
cp -R "./build/Release/MiaoYan.app" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

mdutil -i off "$STAGING_DIR" >/dev/null 2>&1 || true

echo "Creating DMG..."
MAX_RETRIES=3
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
	if ! hdiutil create -quiet -volname "$APP_NAME" \
		-srcfolder "$STAGING_DIR" \
		-ov -format UDZO \
		-imagekey zlib-level=9 \
		"$DMG_BASE_PATH"; then
		echo -e "${YELLOW}hdiutil create failed. Retrying ($((RETRY_COUNT + 1))/$MAX_RETRIES)...${NC}"
		sleep 2
		RETRY_COUNT=$((RETRY_COUNT + 1))
		continue
	fi
	break
done

if [ ! -f "./build/$DMG_NAME" ]; then
	echo -e "${RED}ERROR: Failed to create DMG after retries${NC}"
	exit 1
fi

rm -rf "$STAGING_DIR"
xattr -cr "./build/$DMG_NAME"

# 5. Move to dist/
echo "[5/5] Collecting artifacts..."
mkdir -p "$DIST_DIR"
mv "./build/$DMG_NAME" "$DIST_DIR/MiaoYan_V${VERSION}.dmg"

echo ""
echo -e "${GREEN}MiaoYan v$VERSION CI build succeeded!${NC}"
ls -lh "$DIST_DIR"
echo ""
