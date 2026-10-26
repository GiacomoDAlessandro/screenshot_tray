import XCTest
@testable import ScreenshotTrayCore

final class LoginStartupTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    override func setUp() {
        suite = "com.screenshottray.login-tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() { defaults.removePersistentDomain(forName: suite) }

    func testRecognizesRealApplicationsRootsAndRejectsLookalikePaths() {
        let home = URL(fileURLWithPath: "/Users/Tray Test", isDirectory: true)
        for path in ["/Applications/Screenshot Tray.app", "/Users/Tray Test/Applications/Screenshot Tray.app"] {
            XCTAssertTrue(LoginStartupPreference.isInstalledApplication(at: URL(fileURLWithPath: path), userHome: home))
        }
        for path in ["/Users/Tray Test/Downloads/Screenshot Tray.app", "/Applications Backup/Screenshot Tray.app", "/Users/Tray Test/Applications Backup/Screenshot Tray.app", "/private/tmp/build/Screenshot Tray.app"] {
            XCTAssertFalse(LoginStartupPreference.isInstalledApplication(at: URL(fileURLWithPath: path), userHome: home))
        }
    }

    func testRegistersOnFirstInstalledLaunchOnly() throws {
        let preference = LoginStartupPreference(defaults: defaults)
        var registrations = 0
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 1)
    }
    func testDownloadOrDevelopmentLaunchDefersUntilInstalled() throws {
        let preference = LoginStartupPreference(defaults: defaults)
        var registrations = 0
        try preference.applyDefaultIfNeeded(isInstalled: false, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 0)
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 1)
    }
    func testExplicitDisableBeforeFirstAttemptIsRespected() throws {
        let preference = LoginStartupPreference(defaults: defaults)
        preference.recordUserChoice()
        var registrations = 0
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 0)
    }
    func testExistingRegistrationOrPendingApprovalDoesNotRegisterAgain() throws {
        let preference = LoginStartupPreference(defaults: defaults)
        var registrations = 0
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: true) { registrations += 1 }
        // A later OS disable must not be reversed.
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 0)
    }
    func testFailureIsReportedAndNotRepeatedAutomatically() throws {
        let preference = LoginStartupPreference(defaults: defaults)
        var registrations = 0
        XCTAssertThrowsError(try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) {
            registrations += 1
            throw NSError(domain: "RegistrationDenied", code: 1)
        })
        try preference.applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 1)
    }
    func testRememberedChoiceSurvivesNewPolicyInstance() throws {
        LoginStartupPreference(defaults: defaults).recordUserChoice()
        var registrations = 0
        try LoginStartupPreference(defaults: defaults).applyDefaultIfNeeded(isInstalled: true, alreadyRegistered: false) { registrations += 1 }
        XCTAssertEqual(registrations, 0)
    }
}
