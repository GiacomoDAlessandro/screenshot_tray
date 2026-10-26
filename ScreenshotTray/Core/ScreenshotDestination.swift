import Foundation
import CoreFoundation

public enum ScreenshotFolderValidation {
    public static func validate(_ folder: URL) throws {
        let values = try folder.resourceValues(forKeys: [.isDirectoryKey, .volumeIsReadOnlyKey])
        guard folder.isFileURL, values.isDirectory == true,
              values.volumeIsReadOnly != true,
              FileManager.default.isWritableFile(atPath: folder.path) else {
            throw DestinationError.folderNotWritable
        }
    }
}

public protocol ScreenshotPreferenceStore {
    func value(forKey key: String) -> Any?
    func update(_ values: [String: Any], removing keys: [String])
    func synchronize() -> Bool
}

/// Uses the preference service, never writes preference plist files directly.
public final class CFPreferencesStore: ScreenshotPreferenceStore {
    private let domain: CFString
    public init(domain: String = "com.apple.screencapture") { self.domain = domain as CFString }
    public func value(forKey key: String) -> Any? {
        CFPreferencesCopyValue(key as CFString, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }
    public func update(_ values: [String: Any], removing keys: [String]) {
        CFPreferencesSetMultiple(values as CFDictionary, keys as CFArray, domain,
                                 kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }
    public func synchronize() -> Bool {
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }
}

public struct ScreenshotDestination {
    private let store: ScreenshotPreferenceStore
    public init(store: ScreenshotPreferenceStore = CFPreferencesStore()) { self.store = store }

    public func setFolder(_ folder: URL) throws {
        guard folder.isFileURL else { throw DestinationError.invalidFolder }
        // macOS 27 uses separate destinations for screenshots and recordings.
        // Set both screenshot generations, leaving all recording settings alone.
        let desired = ["location": folder.path, "target": "file",
                       "location-screenshot": folder.path, "target-screenshot": "file"]
        var previous: [String: Any] = [:]
        var previouslyAbsent: [String] = []
        for key in desired.keys {
            if let value = store.value(forKey: key) { previous[key] = value }
            else { previouslyAbsent.append(key) }
        }
        store.update(desired, removing: [])
        let persisted = store.synchronize()
        let matches = desired.allSatisfy { (store.value(forKey: $0.key) as? String) == $0.value }
        guard persisted && matches else {
            store.update(previous, removing: previouslyAbsent)
            guard store.synchronize() else { throw DestinationError.restoreFailed }
            throw DestinationError.couldNotSave
        }
    }
}

public enum DestinationError: LocalizedError {
    case invalidFolder, folderNotWritable, couldNotSave, restoreFailed
    public var errorDescription: String? {
        switch self {
        case .invalidFolder: return "Choose a local folder for screenshots."
        case .folderNotWritable: return "This folder cannot save new files. Choose a writable folder on an available disk. No screenshot settings have been changed."
        case .couldNotSave: return "macOS did not accept the screenshot save location. Your watched folder has not changed. Try again, or set the folder in Command + Shift + 5 → Options → Other Location."
        case .restoreFailed: return "macOS could not finish changing or restoring the screenshot destination. Your watched folder has not changed. Check Command + Shift + 5 → Options → Other Location before taking your next screenshot."
        }
    }
}
