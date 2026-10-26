import AppKit
import SwiftUI
import ServiceManagement
import ImageIO

actor ImageWorker {
    private var cache: [String: CGImage] = [:]
    private var order: [String] = []
    func thumbnail(_ record: Screenshot, access: FolderAccess) -> CGImage? {
        _ = access // retain the folder lease through decoding
        if let image = cache[record.version] { return image }
        guard let image = autoreleasepool(invoking: { ImageLibrary.thumbnail(record.url) }) else { return nil }
        cache[record.version] = image
        order.append(record.version)
        while order.count > 60 { cache.removeValue(forKey: order.removeFirst()) }
        return image
    }
    func clipboardData(_ url: URL, access: FolderAccess) -> Data? {
        _ = access
        return autoreleasepool {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
                  let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            return NSBitmapImageRep(cgImage: cg).tiffRepresentation
        }
    }
}

@MainActor final class TrayModel: ObservableObject {
    enum Page { case tray, settings, setup }
    @Published var page: Page = .tray
    @Published var screenshots: [Screenshot] = []
    @Published var folderURL: URL?
    @Published var folderError: String?
    @Published var message: String?
    @Published var scanning = false
    @Published var copying = false
    @Published var revision = 0
    @Published var shortcut = TrayShortcut()
    @Published var shortcutEnabled = true
    @Published var loginStatus = SMAppService.mainApp.status
    let images = ImageWorker()
    var requestTray: (() -> Void)?
    private(set) var access: FolderAccess?
    private var watcher: DirectoryWatcher?
    private var timer: Timer?
    private var debounce: Task<Void, Never>?
    private var generation = UUID()
    private var pendingScan = false
    private let hotKey = HotKey()

    init() {
        if let data = UserDefaults.standard.data(forKey: "shortcut"),
           let saved = try? JSONDecoder().decode(TrayShortcut.self, from: data), saved.keyCode != nil { shortcut = saved }
        shortcutEnabled = UserDefaults.standard.object(forKey: "shortcutEnabled") as? Bool ?? true
        do { try hotKey.configure(shortcutEnabled ? shortcut : nil) } catch { message = error.localizedDescription }
        do {
            if let saved = try FolderBookmarks.restore() { useFolder(saved) }
            else { page = .setup }
        } catch {
            folderError = "The saved folder is missing or access could not be restored. Choose it again. \(error.localizedDescription)"
            page = .setup
        }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func setToggle(_ action: @escaping () -> Void) { hotKey.onToggle = action }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Screenshot Folder"
        panel.message = "Choose or create a dedicated folder. This does not change where macOS saves screenshots."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        panel.directoryURL = folderURL
        NSApp.activate(ignoringOtherApps: true)
        defer { requestTray?() }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let candidate = FolderAccess(url)
        do {
            // Validate access before replacing the working folder or saved bookmark.
            _ = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            try FolderBookmarks.save(url)
            useFolder(candidate)
            page = .setup
        } catch { message = "Could not use this folder: \(error.localizedDescription)" }
    }

    private func useFolder(_ candidate: FolderAccess) {
        watcher?.stop(); watcher = nil
        debounce?.cancel()
        generation = UUID()
        scanning = false; pendingScan = false
        access = candidate; folderURL = candidate.url
        screenshots = []; folderError = nil
        refresh()
    }

    func scheduleRefresh() {
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    func refresh() {
        loginStatus = SMAppService.mainApp.status
        guard let access else { return }
        guard !scanning else { pendingScan = true; return }
        scanning = true
        let token = generation
        Task { [self] in
            let result = await Task.detached(priority: .utility) {
                Result { try ImageLibrary.scan(access.url) }
            }.value
            guard token == generation else { return }
            scanning = false
            switch result {
            case .success(let records):
                screenshots = records; folderError = nil; revision += 1
                // Reopen each reconciliation so a replaced directory never leaves a stale descriptor.
                watcher?.stop()
                watcher = DirectoryWatcher(url: access.url) { [weak self] in self?.scheduleRefresh() }
            case .failure(let error):
                screenshots = []; watcher?.stop(); watcher = nil
                let ns = error as NSError
                if ns.domain == NSCocoaErrorDomain && [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(ns.code) {
                    folderError = "Screenshot folder is missing. Reconnect its disk, restore it, or choose another folder."
                } else {
                    folderError = "Cannot read the screenshot folder. Check its permissions or choose it again. \(error.localizedDescription)"
                }
            }
            if pendingScan { pendingScan = false; scheduleRefresh() }
        }
    }

    func thumbnail(_ record: Screenshot) async -> NSImage? {
        guard let access else { return nil }
        guard let cg = await images.thumbnail(record, access: access) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    private func existing(_ record: Screenshot) -> Bool {
        guard FileManager.default.isReadableFile(atPath: record.url.path) else {
            message = "This image has moved, disappeared, or is no longer readable."
            refresh(); return false
        }
        return true
    }
    func open(_ record: Screenshot) {
        guard existing(record) else { return }
        NSWorkspace.shared.open([record.url], withApplicationAt: NSWorkspace.shared.urlForApplication(toOpen: record.url) ?? URL(fileURLWithPath: "/System/Applications/Preview.app"), configuration: .init()) { [weak self] _, error in
            if let error { Task { @MainActor in self?.message = "Could not open image: \(error.localizedDescription)" } }
        }
    }
    func reveal(_ record: Screenshot) {
        guard existing(record) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([record.url])
    }
    func drag(_ record: Screenshot) -> NSItemProvider {
        guard existing(record) else { return NSItemProvider() }
        return NSItemProvider(object: record.url as NSURL)
    }
    func copy(_ record: Screenshot) {
        guard !copying, existing(record), let access else { return }
        copying = true
        Task {
            let data = await images.clipboardData(record.url, access: access)
            copying = false
            guard let data, existing(record) else {
                message = "Could not copy the image. It may still be saving or may be unreadable."
                return
            }
            NSPasteboard.general.clearContents()
            if NSPasteboard.general.setData(data, forType: .tiff) { message = "Image copied." }
            else { message = "The clipboard could not accept this image. Try again." }
        }
    }
    func openFolder() {
        guard let folderURL else { return }
        if !NSWorkspace.shared.open(folderURL) { message = "Could not open the folder. Check that it is available." }
    }
    func updateShortcut(_ value: TrayShortcut, enabled: Bool) {
        guard value != shortcut || enabled != shortcutEnabled else { return }
        do {
            try hotKey.configure(enabled ? value : nil)
            shortcut = value; shortcutEnabled = enabled
            UserDefaults.standard.set(try JSONEncoder().encode(value), forKey: "shortcut")
            UserDefaults.standard.set(enabled, forKey: "shortcutEnabled")
        } catch { message = error.localizedDescription }
    }
    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch { message = "Launch at Login could not be changed: \(error.localizedDescription). Install the app in Applications and try again." }
        loginStatus = SMAppService.mainApp.status
    }
}
