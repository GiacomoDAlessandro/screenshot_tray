# Screenshot Tray Implementation Plan

**Goal:** Build a standalone native macOS menu bar screenshot tray from the supplied specification.
**Architecture:** AppKit lifecycle and popover, SwiftUI pages, independently testable filesystem and shortcut logic. Background ImageIO work with bounded caching.
**Tech Stack:** Swift 5 language mode, SwiftUI, AppKit, ImageIO, UniformTypeIdentifiers, ServiceManagement, Carbon. macOS 13+.
**Spec:** design.md and the user's full brief.

## Constraints and review focus

Local only; read-only selected folder; no recursive scanning, capture, deletion, network, or preference modifications. Check partial writes, stale work after switching folders, removed/replaced folders, symlinks, and shortcut registration failure.

- [x] Write and run focused filesystem/shortcut tests against initial empty behavior; observe failure.
- [x] Implement scanning, thumbnail generation, watcher and hotkey validation; pass tests.
- [x] Implement bookmarks, lifecycle, image actions, folder setup, settings, login and global shortcut.
- [x] Generate Xcode project and build standalone universal Release app.
- [x] Run core suite, review sources, inspect signature/entitlements/bundle and perform available launch checks.
- [x] Document exact install/build steps, actual checks, and remaining interactive checks.

Execution decisions: work in the supplied empty checkout; no worktree, commits, or publishing were needed. Use the user's brief as the approved implementation scope, with direct execution as requested. Apply the planning/verification workflow proportionately. Delegate only the final read-only review required by the review skill. Keep external application/login/desktop interactions on a clearly marked manual checklist. See verification.md for evidence.
