import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?
    private var markupController: MarkupWindowController?
    private var previousApp: NSRunningApplication?
    /// True from the start of a capture until its markup window closes, so only one runs at a time.
    private var isBusy = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKey = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey)) { [weak self] in
            self?.startCapture()
        }
        if hotKey == nil {
            NSLog("Huginn: could not register Ctrl+Space")
        }
    }

    func startCapture() {
        guard !isBusy else { return }

        // Without permission screencapture only sees the wallpaper. Ask, and let
        // the user retry once it's granted.
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            return
        }

        isBusy = true
        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApp = frontmost == .current ? nil : frontmost

        CaptureService.capture { [weak self] capture in
            guard let self else { return }
            guard let capture else {
                self.finish()
                return
            }
            let controller = MarkupWindowController(capture: capture) { [weak self] in
                self?.finish()
            }
            self.markupController = controller
            controller.present()
        }
    }

    private func finish() {
        markupController = nil
        isBusy = false
        previousApp?.activate()
        previousApp = nil
    }
}
