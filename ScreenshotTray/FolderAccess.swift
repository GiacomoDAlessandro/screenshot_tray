import AppKit

/// Retained by outstanding work so changing folders cannot revoke access mid-read.
final class FolderAccess: @unchecked Sendable {
    let url: URL
    private let scoped: Bool
    init(_ url: URL) { self.url = url; scoped = url.startAccessingSecurityScopedResource() }
    deinit { if scoped { url.stopAccessingSecurityScopedResource() } }
}

enum FolderBookmarks {
    static let key = "watchedFolderBookmark"
    static func prepare(_ url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope],
                             includingResourceValuesForKeys: nil, relativeTo: nil)
    }
    static func save(_ url: URL) throws { UserDefaults.standard.set(try prepare(url), forKey: key) }
    static func restore() throws -> FolderAccess? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                          relativeTo: nil, bookmarkDataIsStale: &stale)
        let access = FolderAccess(url)
        if stale { try save(url) }
        return access
    }
}
