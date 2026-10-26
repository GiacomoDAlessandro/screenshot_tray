import XCTest
@testable import ScreenshotTrayCore

final class DestinationTests: XCTestCase {
    func testRejectsUnwritableFolderAndAcceptsWritableFolder() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
            try? FileManager.default.removeItem(at: folder)
        }
        XCTAssertNoThrow(try ScreenshotFolderValidation.validate(folder))
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder.path)
        XCTAssertThrowsError(try ScreenshotFolderValidation.validate(folder))
    }
    func testRejectsMissingFolderAndRegularFile() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try ScreenshotFolderValidation.validate(file))
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        XCTAssertThrowsError(try ScreenshotFolderValidation.validate(file))
    }
    func testSetsLegacyAndModernFileDestinationWithoutChangingOtherPreferences() throws {
        let store = TestPreferenceStore(values: ["target": "clipboard", "target-screenshot": "clipboard", "type": "jpg", "location-screenrecording": "/Movies"])
        try ScreenshotDestination(store: store).setFolder(URL(fileURLWithPath: "/Pictures/Images with spaces"))
        XCTAssertEqual(store.values["location"] as? String, "/Pictures/Images with spaces")
        XCTAssertEqual(store.values["location-screenshot"] as? String, "/Pictures/Images with spaces")
        XCTAssertEqual(store.values["target"] as? String, "file")
        XCTAssertEqual(store.values["target-screenshot"] as? String, "file")
        XCTAssertEqual(store.values["type"] as? String, "jpg")
        XCTAssertEqual(store.values["location-screenrecording"] as? String, "/Movies")
    }
    func testSynchronizationFailureRestoresExistingAndAbsentValues() {
        let store = TestPreferenceStore(values: ["location": "/Old", "target": "clipboard", "type": "heic"])
        store.failNextSynchronization = true
        XCTAssertThrowsError(try ScreenshotDestination(store: store).setFolder(URL(fileURLWithPath: "/New")))
        XCTAssertEqual(store.values["location"] as? String, "/Old")
        XCTAssertEqual(store.values["target"] as? String, "clipboard")
        XCTAssertNil(store.values["location-screenshot"])
        XCTAssertNil(store.values["target-screenshot"])
        XCTAssertEqual(store.values["type"] as? String, "heic")
    }
    func testReadbackFailureRestoresPriorDestination() {
        let store = TestPreferenceStore(values: ["location": "/Old", "target": "file"])
        store.ignoreNextWrite = true
        XCTAssertThrowsError(try ScreenshotDestination(store: store).setFolder(URL(fileURLWithPath: "/New")))
        XCTAssertEqual(store.values["location"] as? String, "/Old")
        XCTAssertNil(store.values["location-screenshot"])
    }
    func testCoreFoundationAdapterPersistsInIsolatedDomain() throws {
        let domain = "com.screenshottray.tests.\(UUID().uuidString)"
        let store = CFPreferencesStore(domain: domain)
        let keys = ["location", "target", "location-screenshot", "target-screenshot"]
        defer { store.update([:], removing: keys); _ = store.synchronize() }
        try ScreenshotDestination(store: store).setFolder(URL(fileURLWithPath: "/Test Images"))
        let reader = CFPreferencesStore(domain: domain)
        XCTAssertTrue(reader.synchronize())
        XCTAssertEqual(reader.value(forKey: "location-screenshot") as? String, "/Test Images")
        XCTAssertEqual(reader.value(forKey: "target-screenshot") as? String, "file")
    }
}

private final class TestPreferenceStore: ScreenshotPreferenceStore {
    var values: [String: Any]
    var failNextSynchronization = false
    var ignoreNextWrite = false
    init(values: [String: Any]) { self.values = values }
    func value(forKey key: String) -> Any? { values[key] }
    func update(_ newValues: [String: Any], removing keys: [String]) {
        if ignoreNextWrite { ignoreNextWrite = false; return }
        keys.forEach { values.removeValue(forKey: $0) }
        values.merge(newValues) { _, new in new }
    }
    func synchronize() -> Bool {
        if failNextSynchronization { failNextSynchronization = false; return false }
        return true
    }
}
