import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct Screenshot: Identifiable, Equatable, Sendable {
    public let url: URL
    public let date: Date
    public let size: Int
    public var id: String { url.path }
    public var version: String { "\(url.path)|\(date.timeIntervalSince1970)|\(size)" }
}

public enum ImageLibrary {
    public static func scan(_ folder: URL, limit: Int = 50) throws -> [Screenshot] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .contentTypeKey,
                                       .contentModificationDateKey, .creationDateKey, .fileSizeKey]
        let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])
        let supported = Set(CGImageSourceCopyTypeIdentifiers() as! [String])
        // Keep only the top N metadata entries. Never decode the entire directory.
        var newest: [Screenshot] = []
        guard limit > 0 else { return [] }
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true,
                  values.isSymbolicLink != true,
                  let type = values.contentType ?? UTType(filenameExtension: url.pathExtension),
                  type.conforms(to: .image), supported.contains(type.identifier) else { continue }
            let record = Screenshot(url: url, date: values.contentModificationDate ?? values.creationDate ?? .distantPast,
                                    size: values.fileSize ?? 0)
            newest.append(record)
            newest.sort { $0.date == $1.date ? $0.url.path < $1.url.path : $0.date > $1.date }
            if newest.count > limit { newest.removeLast() }
        }
        return newest
    }
    public static func thumbnail(_ url: URL, maxPixelSize: Int = 480) -> CGImage? {
        guard maxPixelSize > 0,
              let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }
}

public struct TrayShortcut: Codable, Equatable, Sendable {
    public var letter: String
    public var shift: Bool
    public init(letter: String = "T", shift: Bool = false) { self.letter = letter; self.shift = shift }
    public var keyCode: UInt32? {
        ["A": UInt32(0), "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7,
         "C": 8, "V": 9, "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16,
         "T": 17, "O": 31, "U": 32, "I": 34, "P": 35, "L": 37, "J": 38, "K": 40,
         "N": 45, "M": 46][letter]
    }
    public var label: String { "⌃⌥⌘" + (shift ? "⇧" : "") + letter }
}
