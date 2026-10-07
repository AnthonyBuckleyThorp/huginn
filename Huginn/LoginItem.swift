import Foundation
import ServiceManagement

enum LoginItem {
    private static let defaultAppliedKey = "launchAtLoginDefaultApplied"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Huginn: could not \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    /// Launch at login is on by default. Applied once, and only from the installed
    /// copy, so a build run from elsewhere doesn't register the wrong path.
    static func enableByDefaultOnFirstLaunch() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: defaultAppliedKey),
              Bundle.main.bundleURL.path.hasPrefix("/Applications/") else { return }
        defaults.set(true, forKey: defaultAppliedKey)
        setEnabled(true)
    }
}
