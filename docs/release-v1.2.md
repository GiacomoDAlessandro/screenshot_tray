Download **Screenshot-Tray.dmg** below. Requires **macOS 13 or later**, on Apple silicon or Intel. No Xcode, Terminal, npm, account, or subscription is needed.

1. Open the downloaded disk image.
2. Drag **Screenshot Tray.app** onto **Applications**.
3. Open the app from Applications and click its stack icon in the menu bar.
4. Choose your screenshot folder once. The app also sets the Mac's screenshot save destination.

Launch at Login enables automatically on first launch from Applications; you can turn it off in Settings. macOS may require Login Items approval. Closing the tray keeps the app running; Quit exits it.

**First-open limitation:** this early release is ad-hoc signed and **not notarized**. There is no Developer ID certificate available for this project, so macOS may block the download or show an unidentified-developer warning. Only open software you trust; see [Apple's guidance](https://support.apple.com/en-us/102445). Do not disable Gatekeeper or other system protections. A fully verified Developer ID/notarized release is not provided here.

The app shows the 50 newest saved images and supports opening, copying image pixels, revealing in Finder, and dragging original files. Screenshots stay local and remain ordinary files. No screenshot files are moved, renamed, or deleted. Clipboard-only screenshots do not appear.

Verification: universal Release build, 22 automated tests, code-signature verification, disk-image/archive checks, and actual Launch at Login registration on the build Mac. Reboot behavior, macOS 13/Intel runtime, browser-quarantined first launch on another Mac, cross-app dragging, and Spaces/full-screen behavior still require interactive verification. Screenshot destination preference keys are undocumented and may change with macOS.

**Alternatives:** Screenshot-Tray.zip contains the same app. SHA256SUMS provides download checksums. GitHub's automatic “Source code” archives are for building the project; choose the DMG or app ZIP for installation.
