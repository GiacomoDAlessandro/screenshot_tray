// Check only the app launched for this build; no Accessibility or Screen Recording access.
import AppKit
import Foundation

let expected = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("dist/Screenshot Tray.app").standardizedFileURL
let deadline = Date().addingTimeInterval(3)
while Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.screenshottray.app")
guard let app = apps.first(where: { $0.bundleURL?.standardizedFileURL == expected }) else {
    fputs("Standalone app was not running after launch.\n", stderr)
    exit(1)
}
guard app.activationPolicy == .accessory else {
    fputs("Unexpected activation policy: \(app.activationPolicy.rawValue)\n", stderr)
    exit(1)
}
print("PASS: Standalone app remains running; accessory policy (no Dock icon).")
print("App: \(app.bundleURL!.path)")
print("Xcode running: \(!NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode").isEmpty)")
// Leave no running copy at the artifact path while rebuilding/copying it.
guard app.terminate() else { fputs("Could not terminate the smoke-test app.\n", stderr); exit(1) }
