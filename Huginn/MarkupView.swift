import AppKit
import Carbon.HIToolbox

enum Tool {
    case rectangle, pen
}

/// Shows the capture and collects marks. Marks are stored in image pixels so
/// export is a straight replay at full resolution.
final class MarkupView: NSView {
    let image: CGImage
    /// Stroke width in image pixels.
    let lineWidth: CGFloat
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?

    private(set) var marks: [Mark] = []
    private var redoStack: [Mark] = []
    private var currentMark: Mark?
    private var dragStart: CGPoint = .zero

    private var tool: Tool = .rectangle {
        didSet { window?.invalidateCursorRects(for: self) }
    }

    init(image: CGImage, lineWidth: CGFloat) {
        self.image = image
        self.lineWidth = lineWidth
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Geometry

    private var imageSize: CGSize { CGSize(width: image.width, height: image.height) }

    /// View points per image pixel.
    private var displayScale: CGFloat {
        min(bounds.width / imageSize.width, bounds.height / imageSize.height)
    }

    private var imageRect: CGRect {
        let size = CGSize(width: imageSize.width * displayScale, height: imageSize.height * displayScale)
        return CGRect(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2,
                      width: size.width, height: size.height)
    }

    private func imagePoint(for event: NSEvent) -> CGPoint {
        let point = convert(event.locationInWindow, from: nil)
        let rect = imageRect
        let x = (point.x - rect.minX) / displayScale
        let y = (point.y - rect.minY) / displayScale
        return CGPoint(x: min(max(x, 0), imageSize.width), y: min(max(y, 0), imageSize.height))
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        let rect = imageRect
        context.interpolationQuality = .high
        context.draw(image, in: rect)

        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: displayScale, y: displayScale)
        MarkRenderer.draw(marks + [currentMark].compactMap { $0 }, in: context, lineWidth: lineWidth)
        context.restoreGState()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: tool == .rectangle ? .crosshair : Self.penCursor)
    }

    private static let penCursor: NSCursor = {
        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.systemRed]))
        guard let image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Pen")?
            .withSymbolConfiguration(config) else { return .crosshair }
        // The pencil tip is the bottom-left corner; cursor hot spots are measured from the top-left.
        return NSCursor(image: image, hotSpot: NSPoint(x: 1, y: image.size.height - 1))
    }()

    // MARK: Mouse

    override func mouseDown(with event: NSEvent) {
        dragStart = imagePoint(for: event)
        switch tool {
        case .rectangle: currentMark = .rectangle(CGRect(origin: dragStart, size: .zero))
        case .pen: currentMark = .path([dragStart])
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = imagePoint(for: event)
        switch currentMark {
        case .rectangle:
            currentMark = .rectangle(CGRect(x: min(dragStart.x, point.x), y: min(dragStart.y, point.y),
                                            width: abs(point.x - dragStart.x), height: abs(point.y - dragStart.y)))
        case .path(var points):
            // Skip samples closer than one screen point to the last one.
            if let last = points.last, hypot(point.x - last.x, point.y - last.y) * displayScale >= 1 {
                points.append(point)
                currentMark = .path(points)
            }
        case nil:
            return
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            currentMark = nil
            needsDisplay = true
        }
        // Ignore clicks that didn't draw anything visible.
        let minimum = 3 / displayScale
        switch currentMark {
        case .rectangle(let rect) where rect.width >= minimum || rect.height >= minimum: break
        case .path(let points) where points.count >= 2: break
        default: return
        }
        marks.append(currentMark!)
        redoStack.removeAll()
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        if !handleKey(event) { super.keyDown(with: event) }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        handleKey(event) || super.performKeyEquivalent(with: event)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased()

        if key == "z" && flags.contains(.command) && !flags.contains(.option) && !flags.contains(.control) {
            flags.contains(.shift) ? redo() : undo()
            return true
        }
        guard flags.subtracting(.shift).isEmpty else { return false }

        switch Int(event.keyCode) {
        case kVK_Space:
            if !event.isARepeat && currentMark == nil { onCommit?() }
            return true
        case kVK_Escape:
            onCancel?()
            return true
        default:
            break
        }
        switch key {
        case "r": tool = .rectangle
        case "p": tool = .pen
        default: return false
        }
        return true
    }

    private func undo() {
        guard currentMark == nil, let mark = marks.popLast() else { return }
        redoStack.append(mark)
        needsDisplay = true
    }

    private func redo() {
        guard currentMark == nil, let mark = redoStack.popLast() else { return }
        marks.append(mark)
        needsDisplay = true
    }
}
