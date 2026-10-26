import SwiftUI
import ServiceManagement

struct TrayView: View {
    @ObservedObject var model: TrayModel
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill").font(.title2).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Screenshot Tray").font(.headline)
                    Text(model.page == .tray ? "Your latest images, ready to reuse" : "A little setup. Everything stays local.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if model.page != .tray {
                    Button { model.page = .tray } label: { Image(systemName: "chevron.left") }
                        .help("Back to tray").accessibilityLabel("Back to tray")
                }
                Button { model.page = .settings } label: { Image(systemName: "gearshape") }
                    .help("Settings").accessibilityLabel("Settings")
            }.padding(18)
            Divider()
            if let message = model.message {
                HStack(alignment: .top) {
                    Text(message).font(.callout).textSelection(.enabled)
                    Spacer(minLength: 4)
                    Button { model.message = nil } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel("Dismiss message")
                }.padding(12).background(Color.accentColor.opacity(0.10))
            }
            Group {
                switch model.page {
                case .tray: tray
                case .settings: settings
                case .setup: setup
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            HStack {
                Button("Open Screenshot Folder", systemImage: "folder") { model.openFolder() }
                    .disabled(model.folderURL == nil)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
            }.controlSize(.small).padding(12)
        }
        .frame(width: 480, height: 650)
        .background(.regularMaterial)
    }

    private var tray: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.folderURL?.lastPathComponent ?? "No folder selected").font(.subheadline.weight(.medium))
                    .lineLimit(1).help(model.folderURL?.path ?? "Choose a screenshot folder")
                Spacer()
                if model.scanning { ProgressView().controlSize(.small) }
                Button { model.refresh() } label: { Image(systemName: "arrow.clockwise") }
                    .help("Refresh images").accessibilityLabel("Refresh images")
            }.padding(.horizontal, 18).padding(.vertical, 10)
            if let error = model.folderError {
                state(symbol: "folder.badge.questionmark", title: "Folder unavailable", text: error)
            } else if model.folderURL == nil {
                state(symbol: "folder.badge.plus", title: "Give screenshots a home", text: "Choose a folder once. We’ll set it as your Mac’s screenshot save location and show its images here.")
            } else if model.screenshots.isEmpty {
                state(symbol: "photo.on.rectangle.angled", title: model.scanning ? "Looking for images…" : "Ready for your first screenshot",
                      text: "Save an image in this folder and it will appear here. Clipboard-only screenshots do not create a file.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(model.screenshots) { record in
                            ScreenshotCard(record: record, model: model).id(record.version)
                        }
                    }.padding(.horizontal, 14).padding(.bottom, 14)
                }
                Text("\(model.screenshots.count) shown · newest first · up to 50 · older files stay in your folder")
                    .font(.caption2).foregroundStyle(.secondary).padding(8)
            }
        }
    }

    private func state(symbol: String, title: String, text: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: symbol).font(.system(size: 40, weight: .light)).foregroundStyle(.secondary)
            Text(title).font(.title3.weight(.semibold))
            Text(text).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Choose Screenshot Folder…") { model.chooseFolder() }.buttonStyle(.borderedProminent)
            Button("Setup instructions") { model.page = .setup }.buttonStyle(.link)
            Spacer()
        }.padding(28)
    }

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "folder.badge.gearshape").font(.system(size: 44, weight: .light)).foregroundStyle(.tint)
                Text("One folder. You’re ready.").font(.title2.weight(.semibold))
                Text("Choose where you want your screenshots saved. We’ll update your Mac’s screenshot destination and connect the tray at the same time.")
                    .font(.body).foregroundStyle(.secondary)
                Button(model.folderURL == nil ? "Choose Screenshot Folder…" : "Change Screenshot Folder…") { model.chooseFolder() }
                    .buttonStyle(.borderedProminent)
                if let url = model.folderURL { Text(url.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                if let error = model.folderError { Text(error).font(.callout).foregroundStyle(.orange) }
                Label("Confirming Set Screenshot Folder changes where this Mac saves future screenshots. Your existing files stay where they are.", systemImage: "info.circle")
                    .font(.callout).foregroundStyle(.secondary)
                Divider()
                Text("Then just take screenshots as usual.").font(.headline)
                Text("Click the menu bar icon to open, copy, reveal, or drag your saved images. Your folder choice is remembered, so setup is only needed once.")
                    .font(.callout).foregroundStyle(.secondary)
                Text("Clipboard-only screenshots will not appear. Images saved while the app is closed appear when it reopens. You can also add images manually.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Show Screenshot Tray") { model.page = .tray; model.refresh() }
                    .disabled(model.folderURL == nil)
            }.padding(24)
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings").font(.title2.weight(.semibold))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screenshot folder").font(.headline)
                    Text(model.folderURL?.path ?? "No folder selected").font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    Text("Changing this folder also changes where your Mac saves screenshots.").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Change Folder…") { model.chooseFolder() }
                        Button("Setup Instructions") { model.page = .setup }
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Launch at Login", isOn: Binding(get: {
                        model.loginStatus == .enabled || model.loginStatus == .requiresApproval
                    }, set: model.setLogin))
                    Text("Install in Applications first. macOS manages your login permission.")
                        .font(.caption).foregroundStyle(.secondary)
                    if model.loginStatus == .requiresApproval {
                        Text("Approval is required in System Settings → General → Login Items.").font(.callout)
                        Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Keyboard shortcut", isOn: Binding(get: { model.shortcutEnabled }, set: {
                        model.updateShortcut(model.shortcut, enabled: $0)
                    }))
                    HStack {
                        Text("⌃ Control  ⌥ Option  ⌘ Command +")
                        Picker("Letter", selection: Binding(get: { model.shortcut.letter }, set: {
                            model.updateShortcut(TrayShortcut(letter: $0, shift: model.shortcut.shift), enabled: model.shortcutEnabled)
                        })) {
                            ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init), id: \.self) { Text($0).tag($0) }
                        }.labelsHidden().frame(width: 65).accessibilityLabel("Shortcut letter")
                    }.font(.caption)
                    Toggle("Also require Shift", isOn: Binding(get: { model.shortcut.shift }, set: {
                        model.updateShortcut(TrayShortcut(letter: model.shortcut.letter, shift: $0), enabled: model.shortcutEnabled)
                    }))
                    Text("Current: \(model.shortcut.label). These modifiers avoid macOS screenshot shortcuts. If another app uses this combination, choose a different letter. Letters use their physical US keyboard positions.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                Label("Local files only. No uploads, accounts, or analytics. Files remain yours in Finder.", systemImage: "lock.shield")
                    .font(.callout).foregroundStyle(.secondary)
                Text("Screenshot Tray 1.1 · macOS 13 or later").font(.caption2).foregroundStyle(.secondary)
            }.padding(24)
        }.onAppear { model.refresh() }
    }
}

private struct ScreenshotCard: View {
    let record: Screenshot
    @ObservedObject var model: TrayModel
    @State private var thumbnail: NSImage?
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { model.open(record) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04))
                    if let thumbnail {
                        Image(nsImage: thumbnail).resizable().scaledToFit().padding(6)
                    } else if loaded {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.exclamationmark")
                            Text("Preview unavailable\nStill saving or unreadable").font(.caption2).multilineTextAlignment(.center)
                        }.foregroundStyle(.secondary)
                    } else { ProgressView().controlSize(.small) }
                }.frame(height: 125).contentShape(Rectangle())
            }.buttonStyle(.plain).help("Open original · drag to another app")
                .accessibilityLabel("Open \(record.url.lastPathComponent)")
                .onDrag { model.drag(record) }
            Text(record.url.lastPathComponent).font(.caption.weight(.medium)).lineLimit(1).truncationMode(.middle)
                .help(record.url.lastPathComponent)
            Text(record.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                .help("File modification date")
            HStack {
                Button("Copy Image") { model.copy(record) }.disabled(model.copying)
                Spacer(minLength: 2)
                Button { model.reveal(record) } label: { Image(systemName: "folder") }
                    .help("Reveal in Finder").accessibilityLabel("Reveal \(record.url.lastPathComponent) in Finder")
            }.controlSize(.small)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.07), lineWidth: 1))
        .contextMenu {
            Button("Open Original") { model.open(record) }
            Button("Copy Image") { model.copy(record) }.disabled(model.copying)
            Button("Reveal in Finder") { model.reveal(record) }
        }
        .task(id: record.version + "|\(model.revision)") {
            if thumbnail == nil {
                thumbnail = await model.thumbnail(record)
                loaded = true
                // Quick retries for screenshot files whose data is still being flushed.
                for delay in [UInt64(500_000_000), 1_500_000_000, 3_000_000_000] {
                    guard thumbnail == nil, !Task.isCancelled else { break }
                    try? await Task.sleep(nanoseconds: delay)
                    guard !Task.isCancelled else { break }
                    thumbnail = await model.thumbnail(record)
                }
            }
        }
    }
}
