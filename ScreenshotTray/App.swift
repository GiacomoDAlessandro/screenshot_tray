import AppKit
import SwiftUI

@main enum ScreenshotTrayMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var item: NSStatusItem!
    private let popover = NSPopover()
    private var model: TrayModel!
    private var wakeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = TrayModel()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "Screenshot Tray")
            button.toolTip = "Screenshot Tray"
            button.target = self
            button.action = #selector(toggleTray)
        }
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 480, height: 650)
        popover.contentViewController = NSHostingController(rootView: TrayView(model: model))
        model.setToggle { [weak self] in self?.toggleTray() }
        model.requestTray = { [weak self] in self?.showTray() }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.model.refresh() } }
        if model.page == .setup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.showTray() }
        }
    }
    @objc func toggleTray() {
        if popover.isShown { popover.performClose(nil) } else { showTray() }
    }
    func showTray() {
        guard let button = item?.button else { return }
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        popover.contentViewController?.view.window?.makeKey()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showTray(); return false
    }
    func applicationWillTerminate(_ notification: Notification) {
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
