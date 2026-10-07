import SwiftUI

@main
struct HuginnApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var launchAtLogin: Bool

    init() {
        LoginItem.enableByDefaultOnFirstLaunch()
        _launchAtLogin = State(initialValue: LoginItem.isEnabled)
    }

    var body: some Scene {
        MenuBarExtra("Huginn", systemImage: "bird") {
            Button("Capture") {
                // Let the menu finish closing before the crosshair appears.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { appDelegate.startCapture() }
            }
            .keyboardShortcut(.space, modifiers: .control)
            Button("Open Screenshots Folder") { ScreenshotSaver.openFolder() }
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in LoginItem.setEnabled(enabled) }
            Divider()
            Button("Quit Huginn") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
