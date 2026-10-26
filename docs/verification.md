# Verification record and manual checklist

## Actually run

Environment: macOS 27.0.1, Apple silicon, Xcode 27.1 (27A9275), Swift 6.4, macOS SDK 27.0. No existing app code or workspace AGENTS.md was found; the supplied AGENTS.md instructions were followed. Current Apple documentation for SMAppService and security-scoped bookmarks was fetched through Context7.

- Initial test run against empty scanner/thumbnail/shortcut behavior: 7 tests, 12 expected assertion failures. Implemented those behaviors and reran successfully.
- Original `swift test`: 9 XCTest tests, 0 failures. Covers newest-50 ordering without modifying/deleting older files; non-English/manual filenames; filtering directories, hidden files, symlinks and non-images; missing/empty folder; rename/add/remove reconciliation; partial-image recovery and thumbnail pixel bound; deterministic equal-date ordering and zero limit; overwrite version changes; shortcut validation; real directory watcher events and cancellation.
- Version 1.1 `swift test`: 15 XCTest tests, 0 failures. Six added tests cover modern/legacy destination writes, preserving recording-specific/format keys, synchronization failure rollback, readback failure rollback, actual CFPreferences persistence in an isolated preference domain, and rejecting missing/file/unwritable destinations while accepting a writable folder. Automated tests do not alter the user's screenshot destination. Initial destination tests failed to compile with the implementation absent. Destination-validation regression tests subsequently produced three expected failures against empty validation, then passed after implementation.
- `bash scripts/build.sh`: universal Release build succeeded; arm64 and x86_64 are both present. The build script copied the standalone bundle to `dist/Screenshot Tray.app` and verified its signature.
- `codesign --verify --deep --strict`: passed. Version 1.1 Release entitlements contain app sandbox, read/write user-selected files (needed for writable-destination validation), app-scoped bookmarks, and a shared-preference read/write exception limited to com.apple.screencapture. No network, Screen Recording, Accessibility, or debugger entitlement.
- A signed sandboxed preference probe passed write, synchronization, and readback against an isolated test domain using the documented exception mechanism. A bare sandboxed executable was rejected before it could run; enclosing it in a proper app bundle fixed the probe harness. Testing the read-only sandbox against a writable filesystem path confirmed writeability checks are restricted by the sandbox, motivating the selected-folder read/write grant. No screenshot destination was changed by this probe.
- The same sandbox probe accepted a writable folder in its own container and rejected it after write permission was removed. No screenshot files were created or changed. A temporary directory fixture was removed after the probe.
- `xcrun vtool -show-build`: both slices declare macOS minimum 13.0. Binary dependencies inspected with `otool -L`: Apple system frameworks/libraries only.
- `plutil -lint`: app plist, entitlements, and Xcode project passed. `bash -n scripts/build.sh`: passed. Custom Finder icon is packaged.
- Launch Services startup smoke test: `open -n "dist/Screenshot Tray.app"`, then `swift scripts/smoke-check.swift`. Confirmed the app remained running and reported accessory activation policy (no Dock icon). Xcode was not running. The smoke script then quit only that build's running copy. This is a startup/lifecycle check, not a visual UI test.
- Independent read-only code review found stale thumbnail state for overwrites at the same path. Fixed by placing the version identity on the card at its call site. Metadata overwrite coverage was added; visual replacement behavior remains on the manual checklist.
- Version 1.1 review identified missing writable-destination validation; added validation before preference updates and verified it with tests that failed first. Documentation now explains legacy shared screenshot/recording destinations instead of promising independent recording destinations on every OS.
- Updated the existing `/Applications/Screenshot Tray.app` to version 1.1 after keeping the previous installed app in ignored `build/Previous Screenshot Tray.app`. Verified the installed signature and opened the new app. No screenshot destination is changed merely by launching this update.

The sandbox initially blocked compiler caches and SwiftUI macro compilation; build and test commands succeeded with the required host-tool access. Xcode prints an App Intents metadata extraction notice because this app does not use AppIntents; there are no source compiler warnings in the final Release build.

## Still requires interactive verification

These are **not claimed as passed**. Use a disposable test folder with generated/sample images. Do not remove personal screenshots to test errors. Test the installed Applications copy, with Xcode and Terminal closed.

### Menu bar and setup

- [ ] Double-click Applications/Screenshot Tray.app. Confirm one menu bar icon, no Dock icon, and no main window.
- [ ] First launch shows setup. Choose a folder, then cancel a subsequent picker; the original selection remains intact.
- [ ] Use New Folder in the native picker. Confirm the folder is created only at your request.
- [ ] Confirm setup/picker explain that Set Screenshot Folder changes the Mac's screenshot destination. Confirm the picker opens directly from one button and success returns to the tray.
- [ ] Choose a folder, take a standard Command + Shift + 3/4 screenshot, and verify the file saves there without opening Apple's Options menu. Check both previously file-saving and Clipboard/Preview destinations. Verify the screenshot toolbar reflects the new folder.
- [ ] Cancel folder selection; verify both the watched folder and screenshot destination stay unchanged. Test an unwritable/missing folder and a failed preference write; errors must not report success.
- [ ] Click icon to toggle; click outside and press Escape to close. The app stays running. Quit exits it.

### Folder access and updates

- [ ] Select a test folder, quit, relaunch; access and existing images are restored without selecting it again.
- [ ] Save screenshots with standard shortcuts. Manually add an image with a non-English filename. Confirm both appear.
- [ ] Add more than 50 images. Only the newest 50 appear and older files remain untouched in Finder.
- [ ] Rename and remove a test image in Finder; confirm changes appear. Add images while the app is closed and reopen it.
- [ ] Overwrite a displayed image at the same path; confirm its thumbnail refreshes as well as its modification date.
- [ ] Copy a large file slowly into the folder; confirm a saving/unreadable placeholder recovers without blocking scrolling. Try a corrupt image; other previews remain usable.
- [ ] Switch from test folder A to B. Add images to A while B is selected; A's images never appear in B. Reopen app and confirm B persists.
- [ ] Rename/remove a disposable watched folder, or disconnect an external test disk. Confirm clear error, no crash, and recovery after restoring it or choosing a new folder.
- [ ] Temporarily deny this app permission to a disposable test folder through normal macOS controls. Confirm a useful error and recovery after selecting an accessible folder. Test sandbox access after installing/replacing the app.
- [ ] Capture to clipboard only. Confirm no file appears in the tray and the explanatory text is accurate.

### Image actions

- [ ] Click a preview: original opens in its configured default app. Reveal selects that exact original in Finder.
- [ ] Copy Image, then paste into Preview (File → New from Clipboard), Notes, or another image-capable app. Verify image pixels, not a pathname or thumbnail. Include a large PNG and an oriented HEIC/JPEG if used.
- [ ] Drag a thumbnail to Finder, Mail, Notes, and any target apps you use. Confirm a usable original file is offered; app support varies. Specifically test sandbox access grants to receiving apps.
- [ ] Remove a disposable file immediately before/during Open, Copy, Reveal, and Drag. Confirm graceful failure; the receiving app may report a race after a drag has begun.

### Login, keyboard, and desktop availability

- [ ] Install in Applications. Enable Launch at Login; approve in macOS Login Items if requested. Log out/in and verify the icon appears without Xcode or Terminal.
- [ ] Disable Launch at Login; log out/in and verify no automatic launch. Check OS-controlled status changes are reflected when reopening settings.
- [ ] Press default Control + Option + Command + T to show/hide. Configure another letter and optional Shift. Verify the former shortcut stops working and disabled shortcuts do nothing.
- [ ] Test a conflict with a shortcut you already use. Confirm failure is reported when the OS rejects registration; if a third-party app intercepts it, choose another combination.
- [ ] Test with your keyboard layout; letter shortcuts are based on physical US key positions.
- [ ] Test on multiple Spaces, an app in native full-screen, menu bar auto-hide, external displays, and Stage Manager if used. Check popover placement and dismissal. Availability depends on macOS and desktop configuration; no universal full-screen guarantee is made.
- [ ] Run on a real macOS 13 Mac and an Intel Mac before claiming runtime compatibility there. Deployment metadata and compilation were checked; neither runtime was available for this session.

## Sources consulted

- [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Apple: sandbox file access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [Apple: startAccessingSecurityScopedResource](https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource())
