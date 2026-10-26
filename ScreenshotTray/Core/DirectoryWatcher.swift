import Foundation

/// Owns one descriptor. Cancellation closes it even if the owner has gone away.
public final class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    public init?(url: URL, changed: @escaping () -> Void) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib, .extend, .link, .revoke], queue: .main)
        source.setEventHandler(handler: changed)
        source.setCancelHandler { close(fd) }
        self.source = source
        source.resume()
    }
    public func stop() { source?.cancel(); source = nil }
    deinit { stop() }
}
