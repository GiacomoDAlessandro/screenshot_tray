# Screenshot Tray

A native, local macOS menu bar app for finding and reusing saved screenshots. No server, npm, accounts, uploads, analytics, or screenshot capture service. Built with Swift, SwiftUI, and AppKit, using Apple frameworks only.

## Install and use the standalone app

The built app is **`dist/Screenshot Tray.app`**. In Finder, open this repository's `dist` folder and drag **Screenshot Tray.app** into **Applications**. Double-click it in Applications. You may close Xcode and Terminal; neither is needed to run the app. The app has a custom icon in Finder and a stack icon in the menu bar, with no Dock icon or main window.

1. Click the menu bar icon and choose or create a dedicated screenshot folder using **Choose Screenshot Folder**. The folder picker has a **New Folder** button.
2. Separately press **Command + Shift + 5 → Options → Other Location**, and choose that same folder. **Selecting a folder in Screenshot Tray does not change the macOS screenshot destination.** The app never changes screenshot preferences.
3. Take an ordinary Mac screenshot. Click the stack icon, or press **Control + Option + Command + T**, to toggle the tray.
4. Click a thumbnail to open the original in its default app. Use **Copy Image** to put actual image data on the clipboard, the folder icon to reveal the original in Finder, or drag the thumbnail into a compatible app.

Click outside the tray or press Escape to dismiss it. The app keeps running. **Quit** exits it. Launch at Login is optional and off until you enable it in Settings. Install the app in Applications before enabling it; macOS may require approval under **System Settings → General → Login Items**.

Settings lets you change/open the folder, revisit setup, manage login startup, and change or disable the shortcut. Changing folders stops watching the previous one. The shortcut uses Control + Option + Command, a chosen letter, and optionally Shift. It uses physical US letter key positions, which may differ on other keyboard layouts. If registration fails, the app reports the error and retains the previous setting. Third-party apps can still conflict with a chosen combination.

## What appears

- The 50 newest supported images in the selected folder, ordered by **file modification date**, with deterministic path ordering for equal dates. Dates shown are file dates, not inferred capture times.
- Images with any filename/language, including manually added files. ImageIO-supported types include PNG, JPEG, HEIC, TIFF, GIF, and other image types supported by the OS. Animated images use their first frame. PDF/SVG, non-images, subfolders, hidden files, and symlinks are excluded.
- The 50-item limit only affects display. Older files are never modified or removed. Manage deletion in Finder.
- Clipboard-only screenshots do not create files and will not appear. Images saved while the app is closed appear on its next launch.
- Directory events are debounced for 350 ms. Scans also run on launch, tray opening, wake, and every 15 seconds to recover missed events and in-place writes. Partially written images get quick preview retries and periodic retries. An unreadable image has a clear placeholder; other images remain usable.

Only direct children of your selected folder are inspected. Directory metadata is scanned off the main thread, keeping only the newest 50 records. Thumbnails are downsampled with ImageIO on a serial background actor and cached with a 60-entry bound. Copying decodes just the chosen original and writes TIFF image data; a very large original can still require significant memory. No full-resolution directory preload occurs.

## Build from source

Requires a Mac and Xcode with the macOS SDK. **Deployment target: macOS 13.0**, the minimum for the supported `SMAppService.mainApp` login API. The source uses Swift 5 language mode for broad compiler compatibility. This delivery was built using Xcode 27.1 / Swift 6.4 / macOS SDK 27.0. Older Xcode releases have not been tested.

**Xcode:** Open `ScreenshotTray.xcodeproj`, choose the shared **ScreenshotTray** scheme and **My Mac**, then Product → Build. For the standalone artifact, choose Release under Edit Scheme → Run → Build Configuration, build, then find Screenshot Tray.app under Products → Show in Finder. Quit any running copy before opening your installed copy. The project defaults to local ad-hoc signing, so no team is needed.

**Reproducible universal Release build:**

```sh
bash scripts/build.sh
```

This uses `xcodebuild`, builds arm64 and x86_64, copies the self-contained app to `dist/Screenshot Tray.app`, and verifies the code signature. It does not install the app or change system preferences. You can run the script again to replace the build artifact; quit the app first. The app contains no development runtime or external executable dependencies.

**Core automated checks:**

```sh
swift test
```

The Swift package exists for core tests; the runnable app is the Xcode project. Tests use temporary generated images, not personal screenshots. See [verification.md](docs/verification.md) for actual results and the interactive checklist.

## Signing and downloads

For **local personal use**, a paid Apple Developer membership is not required. The provided build script signs locally with the ad-hoc identity `-`, including sandbox entitlements. This provides a local code signature, not a verified developer identity or Apple notarization. Xcode can also use your own available signing identity; keep certificates and credentials out of Git. If a replacement build changes signing identity, you may need to select the folder again and re-enable login startup.

For distribution to other Macs, Developer ID signing and Apple notarization normally require paid membership. Neither has been performed. An unsigned or ad-hoc signed **GitHub download** may be quarantined, blocked by Gatekeeper, or fail trust/permission checks on another Mac. A successful local build is not evidence that such a download will open normally. Build from source locally, or obtain a properly signed and notarized release. Do not disable Gatekeeper, SIP, or other system security settings. No repository or release has been published by this task.

## Privacy and access

The app is sandboxed with **read-only access to a user-selected folder** and an app-scoped security bookmark. Bookmarks and shortcut preferences stay in the app's local UserDefaults container. Folder creation happens only through the native picker when you request it. There are no network entitlements. No Screen Recording or Accessibility permission is required. Only permission to the folder you choose is needed; macOS may show its normal files/folders prompt for protected locations.

Access is restored with the stored bookmark on launch, and stale bookmarks are renewed. Folder access remains alive while outstanding reads finish; stale scan results from a previous folder are discarded. Screenshots remain ordinary files usable without Screenshot Tray.

## Troubleshooting and limitations

- **Nothing appears:** Check that the screenshot toolbar's destination matches the app folder. Clipboard-only capture does not save a file. Open the folder from the tray and check that supported images exist directly inside it. Use Refresh, or wait up to 15 seconds for reconciliation.
- **Missing folder / permission error:** Reconnect an external disk, restore the folder, or use Change Folder to grant access again. The app keeps the saved choice and retries. An unreadable individual image can still be revealed in Finder.
- **Preview unavailable:** Let the file finish saving. The app retries without deleting or rewriting it. Corrupt or unsupported data may never generate a preview.
- **File vanished during an action:** The app checks access and reports copy/open failures. A file can still vanish after a Finder reveal or drag starts; Finder or the receiving app may report the final race. Refresh the tray and retry with the current file.
- **Launch at Login fails:** Confirm you are running the installed Applications copy, then check macOS Login Items approval. The setting reflects `SMAppService` status and reports registration errors. Login with ad-hoc builds and permission restoration after rebuilds require verification on your Mac.
- **Shortcut unavailable:** Choose another letter/Shift setting, or disable the shortcut and use the menu bar icon. No event-tap or Accessibility access is used.
- **Menu bar icon hidden:** Check menu bar utilities, a display notch, or a crowded menu bar. A global shortcut can open the tray only while the app is running and the status item is available.
- **Spaces / full-screen:** The transient popover requests all-Spaces and full-screen auxiliary behavior. macOS, menu bar auto-hide, Stage Manager, another app's full-screen mode, and display configuration can affect where it appears. Universal availability is not promised; the real interaction checklist remains required. There is no pinned or always-open mode.
- **Uninstall:** Disable Launch at Login, quit the app, then remove it from Applications with Finder. Screenshot files are unaffected. Local app preferences may remain in its sandbox container.

The initial scope intentionally contains no capture replacement, editing, moving, renaming, deletion, OCR, AI, tags, cloud, subscription, or recursive computer scanning.
