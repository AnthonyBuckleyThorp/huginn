import AppKit
import ImageIO

struct Capture {
    let image: CGImage
    /// The display the selection was made on, used for placement and pixel density.
    let screen: NSScreen
}

/// Runs macOS's own interactive selection via screencapture.
enum CaptureService {
    static func capture(completion: @escaping (Capture?) -> Void) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("huginn-\(UUID().uuidString).png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", url.path]
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                // screencapture doesn't say which display was used; the pointer is
                // still where the drag ended.
                let mouse = NSEvent.mouseLocation
                defer { try? FileManager.default.removeItem(at: url) }

                // No file means the selection was cancelled.
                let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let image = CGImageSourceCreateImageAtIndex(source, 0, options),
                      let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
                        ?? NSScreen.main
                else {
                    completion(nil)
                    return
                }
                completion(Capture(image: image, screen: screen))
            }
        }

        do {
            try process.run()
        } catch {
            NSLog("Huginn: screencapture failed to start: \(error)")
            completion(nil)
        }
    }
}
