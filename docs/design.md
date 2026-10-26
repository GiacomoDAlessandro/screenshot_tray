# Screenshot Tray

The user's supplied brief is the product specification. Implement directly in the supplied empty workspace, with no dependency installs, publishing, screenshot preference changes, or personal data committed.

Use a native NSStatusItem and transient NSPopover containing SwiftUI. No main window or Dock icon. Settings and setup are pages inside the popover; the folder picker can create folders. macOS 13 is the minimum because Launch at Login uses SMAppService.mainApp (introduced in 13). The app is sandboxed with read-only user-selected files and app-scoped bookmarks, and has no network entitlement.

Scan direct children only, excluding hidden files, directories, and symbolic links. Accept ImageIO-supported image types independent of filenames. Sort by modification date descending, with deterministic path tie-breaking. Show at most 50, never change files. ImageIO produces downsampled thumbnails on a background worker, with bounded caching and serial decoding. Read failures remain visible and retry on periodic refreshes.

Hold security-scoped access for each folder session; release after outstanding work finishes. Changing folders cancels the previous watcher immediately and discards stale results. Watch directory changes, debounce events, rescan on tray opening and wake, and reconcile every 15 seconds. Folder deletion/replacement and missed/in-place write events recover through reconciliation.

Use Carbon RegisterEventHotKey (no event taps or Accessibility permission). Configurable letter and optional Shift, with Command+Control+Option required; default T. Registration failure is shown and retains the prior registered shortcut. No shortcut can be guaranteed conflict-free with third-party apps.

Deliver an Xcode project, dependency-free core test package, universal ad-hoc signed Release app, build script, README, and manual test checklist. Local app builds do not require paid membership. Ad-hoc signing is not notarization or trusted distribution. Real Spaces, full-screen, login, permission restoration, and cross-app drag behavior require interactive verification.
