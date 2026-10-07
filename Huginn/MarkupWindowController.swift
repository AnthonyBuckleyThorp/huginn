import AppKit

final class MarkupWindowController: NSWindowController, NSWindowDelegate {
    private let capture: Capture
    private let markupView: MarkupView
    private let onClose: () -> Void
    /// The capture's size in points on its display, before any shrinking to fit.
    private let pointSize: NSSize

    init(capture: Capture, onClose: @escaping () -> Void) {
        self.capture = capture
        self.onClose = onClose

        let scale = capture.screen.backingScaleFactor
        pointSize = NSSize(width: CGFloat(capture.image.width) / scale, height: CGFloat(capture.image.height) / scale)
        // About 4 pt at 1x, so 8 px on a Retina capture.
        markupView = MarkupView(image: capture.image, lineWidth: 4 * scale)

        let window = NSWindow(contentRect: NSRect(origin: .zero, size: pointSize),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "R box · P pen · ⌘Z undo · Space copy · Esc discard"
        window.isReleasedWhenClosed = false
        window.level = .floating
        // Show over full-screen apps, in whichever Space is active.
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.contentView = markupView

        super.init(window: window)
        window.delegate = self
        markupView.onCommit = { [weak self] in self?.commit() }
        markupView.onCancel = { [weak self] in self?.close() }
        placeOnCaptureScreen(window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func present() {
        guard let window else { return }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(markupView)
    }

    private func placeOnCaptureScreen(_ window: NSWindow) {
        let visible = capture.screen.visibleFrame.insetBy(dx: 20, dy: 20)
        let titleBarHeight = window.frameRect(forContentRect: .zero).height
        let fit = min(1, visible.width / pointSize.width, (visible.height - titleBarHeight) / pointSize.height)
        window.setContentSize(NSSize(width: (pointSize.width * fit).rounded(),
                                     height: (pointSize.height * fit).rounded()))
        var frame = window.frame
        frame.origin = NSPoint(x: (visible.midX - frame.width / 2).rounded(),
                               y: (visible.midY - frame.height / 2).rounded())
        window.setFrame(frame, display: false)
    }

    private func commit() {
        let date = Date()
        guard let png = Exporter.pngData(image: capture.image, marks: markupView.marks,
                                         lineWidth: markupView.lineWidth, pointSize: pointSize) else {
            NSSound.beep()
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)
        close()

        DispatchQueue.global(qos: .utility).async {
            do {
                try ScreenshotSaver.save(png, date: date)
            } catch {
                Notifier.post(title: "Screenshot copied but not saved", body: error.localizedDescription)
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
