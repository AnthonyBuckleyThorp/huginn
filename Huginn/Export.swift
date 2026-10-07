import AppKit
import UserNotifications

enum Exporter {
    /// Flattens the marks onto the capture at its original pixel size.
    static func pngData(image: CGImage, marks: [Mark], lineWidth: CGFloat, pointSize: NSSize) -> Data? {
        let colorSpace = image.colorSpace.flatMap { $0.model == .rgb ? $0 : nil }
            ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(data: nil, width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        MarkRenderer.draw(marks, in: context, lineWidth: lineWidth)
        guard let flattened = context.makeImage() else { return nil }

        let rep = NSBitmapImageRep(cgImage: flattened)
        // Records the Retina DPI so apps show it at its on-screen size.
        rep.size = pointSize
        return rep.representation(using: .png, properties: [:])
    }
}

enum ScreenshotSaver {
    static var folder: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures/Screenshots", isDirectory: true)
    }

    @discardableResult
    static func save(_ png: Data, date: Date) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let base = "Screenshot \(formatter.string(from: date))"

        var url = folder.appendingPathComponent("\(base).png")
        var counter = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = folder.appendingPathComponent("\(base) (\(counter)).png")
            counter += 1
        }
        try png.write(to: url, options: .withoutOverwriting)
        return url
    }

    static func openFolder() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }
}

enum Notifier {
    static func post(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}
