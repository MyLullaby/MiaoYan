# MiaoYan Agent Guide

## Project

MiaoYan is a lightweight Markdown editor built with Swift. The main app is macOS/AppKit, and the repository also contains an iOS target under `MiaoYanMobile/`.

## Repository Map

- `Controllers/` - view controllers and window controllers.
- `Views/` - UI components.
- `Business/` - models and business logic.
- `Helpers/` - utilities and services.
- `Extensions/` - Swift extensions.
- `Resources/` - bundled resources.
- `MiaoYanMobile/` - iOS app target, SwiftUI views, mobile services, and mobile resources.
- `MiaoYan.xcodeproj/` - Xcode project and version settings.
- `Package.swift` - Swift package dependency declarations and supported platforms.
- `scripts/` - local build, App Store, release, and project maintenance scripts.
- `scripts/release-ci/` - release note rendering, appcast, notarization, and package helpers.
- `.github/RELEASE_NOTES.md` - public release note source for GitHub release and appcast body generation.
- `.github/workflows/` - sponsor asset maintenance workflows; release builds are not currently driven by a tracked release workflow.

## Commands

```bash
xcodebuild -project MiaoYan.xcodeproj -scheme MiaoYan -configuration Debug build
xcodebuild clean
swiftlint lint --strict
swift-format lint --recursive .
bash scripts/build.sh
bash scripts/build-appstore.sh
```

Use the narrowest relevant command first. Full app builds are the default verification for Swift or project changes.

## Working Rules

- Follow existing Swift and AppKit patterns.
- Keep UI updates on the main thread.
- Avoid force unwraps unless the invariant is obvious and local.
- Keep file writes scoped to user documents or app-controlled locations.
- Do not add network calls, shell execution, or broad file access without clear user need.
- Keep AppKit patterns in the macOS app and SwiftUI patterns in `MiaoYanMobile/`; do not mix frameworks across targets without a clear task reason.
- Preserve recoverability for delete flows. Notes and attachments should move through the app Trash or system Trash path that matches the current context, not disappear through direct deletion.
- Treat iCloud sync and symlinked directories as file-system-sensitive surfaces; resolve paths deliberately and avoid loops or duplicate indexing.

## Investigation Order

When scope is incomplete, start with:

1. `Controllers/AppDelegate.swift`
2. `Controllers/MainWindowController.swift`
3. `Controllers/ViewController.swift`
4. `MiaoYanMobile/` when the task touches iOS, sync, mobile reading, or mobile editing behavior
5. Narrow related files under `Helpers/`, `Views/`, `Business/`, or `Extensions/`
6. Relevant Xcode project settings only when build, signing, target membership, or version behavior is involved

Avoid broad scans of `build/`, `.build/`, `dist/`, and bundled web assets unless the task targets them.

## Current Risk Areas

- Wikilinks and backlinks depend on `Business/WikilinkIndex.swift`, note loading, search, and sidebar refresh behavior. Keep `[[note]]` parsing, recursive search, and Trash exclusions consistent.
- iCloud sync spans macOS storage, `Business/CloudSyncManager.swift`, and `MiaoYanMobile/Services/CloudSyncManager.swift`. Verify fallback behavior when iCloud is unavailable.
- `MiaoYanMobile/` is a real iOS target, not sample code. Keep SwiftUI, file reading, mobile rendering, and target membership aligned.
- Trash handling spans `Business/Storage.swift`, `Business/Note.swift`, sidebar drag/drop, attachment cleanup, and system Trash fallback.
- Version history lives in `Business/NoteVersionManager.swift` and `Controllers/VersionHistoryViewController.swift`; keep file IO off the main thread and UI updates on the main thread.
- Mermaid and PDF export span `Business/HtmlManager.swift`, `Helpers/PdfExportController.swift`, and `Extensions/MPreviewView+Export.swift`. Wait for images and Mermaid rendering before capture.
- Async note/image/file loading is intentional. Do not reintroduce blocking reads on the main thread for large notes or previews.
- Directory symlinks are supported by storage scanning. Avoid recursion loops and duplicate notes when following symlinked directories.

## Release Notes

- Tag format is uppercase `Vx.y.z`.
- Version changes must keep `MARKETING_VERSION` in `MiaoYan.xcodeproj/project.pbxproj` aligned with the release tag.
- `.github/RELEASE_NOTES.md` is the public release note source. Release scripts under `scripts/release-ci/` render it for GitHub release and appcast content, including the current sectionless format.
- Direct-download release builds use repository scripts. The tracked GitHub workflows currently maintain sponsor assets, not release packaging.
- Release automation depends on maintainer-managed signing, notarization, and Sparkle credentials. Do not document or commit local credential paths, private key filenames, or secret values.

## Verification

- Swift changes: run the Debug `xcodebuild` command above.
- Lint or formatting changes: run SwiftLint and swift-format checks.
- iOS changes: inspect `MiaoYanMobile/` target membership and run the narrowest relevant Xcode build or project check available.
- Release or signing changes: verify version alignment and inspect the relevant repository script; do not assume a tracked `release.yml` exists.
- Release note changes: inspect `.github/RELEASE_NOTES.md` and the affected `scripts/release-ci/` renderer.
- Export changes: verify Mermaid, images, PDF pagination, and async readiness behavior together.
- Documentation-only changes: check links and command accuracy.
