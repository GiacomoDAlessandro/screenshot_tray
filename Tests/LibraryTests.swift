import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import ScreenshotTrayCore

final class LibraryTests: XCTestCase {
    var folder: URL!
    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: folder) }

    @discardableResult func image(_ name: String, date: TimeInterval = 100, width: Int = 32) throws -> URL {
        let url = folder.appendingPathComponent(name)
        let context = CGContext(data: nil, width: width, height: 32, bitsPerComponent: 8,
                                bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: date)], ofItemAtPath: url.path)
        return url
    }
    func testNewestFiftyWithoutModifyingOlderFiles() throws {
        for i in 0..<57 { try image("画像-\(i).png", date: Double(i)) }
        let records = try ImageLibrary.scan(folder)
        XCTAssertEqual(records.count, 50)
        XCTAssertEqual(records.first?.url.lastPathComponent, "画像-56.png")
        XCTAssertEqual(records.last?.url.lastPathComponent, "画像-7.png")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path).count, 57)
        XCTAssertEqual(try folder.appendingPathComponent("画像-0.png").resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate, Date(timeIntervalSince1970: 0))
    }
    func testFiltersNonImagesDirectoriesHiddenFilesAndSymlinks() throws {
        try image("手動.png")
        try image(".hidden.png")
        try Data("text".utf8).write(to: folder.appendingPathComponent("notes.txt"))
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("nested.png"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(atPath: folder.appendingPathComponent("linked.png").path, withDestinationPath: folder.appendingPathComponent("手動.png").path)
        XCTAssertEqual(try ImageLibrary.scan(folder).map { $0.url.lastPathComponent }, ["手動.png"])
    }
    func testReconciliationFindsRenamesRemovalsAndNewFiles() throws {
        let original = try image("first.png")
        XCTAssertEqual(try ImageLibrary.scan(folder).count, 1)
        try FileManager.default.moveItem(at: original, to: folder.appendingPathComponent("renamed.png"))
        try image("new.png", date: 200)
        XCTAssertEqual(try ImageLibrary.scan(folder).map { $0.url.lastPathComponent }, ["new.png", "renamed.png"])
        try FileManager.default.removeItem(at: folder.appendingPathComponent("renamed.png"))
        XCTAssertEqual(try ImageLibrary.scan(folder).count, 1)
    }
    func testMissingFolderThrowsAndEmptyFolderIsEmpty() throws {
        XCTAssertTrue(try ImageLibrary.scan(folder).isEmpty)
        XCTAssertThrowsError(try ImageLibrary.scan(folder.appendingPathComponent("absent")))
    }
    func testPartialImageRecoversAndThumbnailIsBounded() throws {
        let url = folder.appendingPathComponent("writing.png")
        try Data([0x89, 0x50]).write(to: url)
        XCTAssertNil(ImageLibrary.thumbnail(url))
        try image("writing.png", width: 2000)
        let thumbnail = try XCTUnwrap(ImageLibrary.thumbnail(url, maxPixelSize: 240))
        XCTAssertLessThanOrEqual(thumbnail.width, 240)
        XCTAssertLessThanOrEqual(thumbnail.height, 240)
    }
    func testStableTieOrderingAndZeroLimit() throws {
        try image("b.png"); try image("a.png")
        XCTAssertEqual(try ImageLibrary.scan(folder).map { $0.url.lastPathComponent }, ["a.png", "b.png"])
        XCTAssertTrue(try ImageLibrary.scan(folder, limit: 0).isEmpty)
    }
    func testOverwriteAtSamePathChangesPreviewVersion() throws {
        try image("overwrite.png", date: 100)
        let before = try XCTUnwrap(ImageLibrary.scan(folder).first)
        try image("overwrite.png", date: 200, width: 100)
        let after = try XCTUnwrap(ImageLibrary.scan(folder).first)
        XCTAssertEqual(before.id, after.id)
        XCTAssertNotEqual(before.version, after.version)
        XCTAssertEqual(after.date, Date(timeIntervalSince1970: 200))
    }
    func testShortcutAcceptsOnlySupportedLetters() {
        XCTAssertEqual(TrayShortcut().keyCode, 17)
        XCTAssertEqual(TrayShortcut(letter: "S", shift: true).keyCode, 1)
        for input in ["3", " ", "", "TT", "é", "s"] { XCTAssertNil(TrayShortcut(letter: input).keyCode) }
    }
    func testDirectoryWatcherReportsChangesAndStops() throws {
        let changed = expectation(description: "directory event")
        changed.assertForOverFulfill = false
        let watcher = try XCTUnwrap(DirectoryWatcher(url: folder) { changed.fulfill() })
        try image("added.png")
        wait(for: [changed], timeout: 3)
        watcher.stop()
        let staleEvent = expectation(description: "stopped watcher must stay silent")
        staleEvent.isInverted = true
        let second = try XCTUnwrap(DirectoryWatcher(url: folder) { staleEvent.fulfill() })
        second.stop()
        try image("after-stop.png")
        wait(for: [staleEvent], timeout: 0.3)
    }
}
