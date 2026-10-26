import Foundation

public struct LoginStartupPreference {
    private let defaults: UserDefaults
    private static let key = "loginStartupDefaultConsidered"
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public static func isInstalledApplication(at url: URL, userHome: URL?) -> Bool {
        var roots = [URL(fileURLWithPath: "/Applications", isDirectory: true)]
        if let userHome { roots.append(userHome.appendingPathComponent("Applications", isDirectory: true)) }
        let path = url.standardizedFileURL.path
        return roots.contains { path.hasPrefix($0.standardizedFileURL.path + "/") }
    }

    public func applyDefaultIfNeeded(isInstalled: Bool, alreadyRegistered: Bool,
                                     register: () throws -> Void) throws {
        guard isInstalled, !defaults.bool(forKey: Self.key) else { return }
        // Record before registration so a denial or later OS disable never causes
        // another automatic request. Manual retries remain available in Settings.
        defaults.set(true, forKey: Self.key)
        if !alreadyRegistered { try register() }
    }

    public func recordUserChoice() {
        defaults.set(true, forKey: Self.key)
    }
}
