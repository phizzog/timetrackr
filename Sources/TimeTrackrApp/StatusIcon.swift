import AppKit

enum StatusIcon {
    static func make(isRunning: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let strokeColor = NSColor.labelColor
        strokeColor.setStroke()
        strokeColor.setFill()

        let bezelRect = NSRect(x: 3.5, y: 2.5, width: 11, height: 11)
        let bezelPath = NSBezierPath(ovalIn: bezelRect)
        bezelPath.lineWidth = 1.6
        bezelPath.stroke()

        let crownPath = NSBezierPath()
        crownPath.lineWidth = 1.6
        crownPath.lineCapStyle = .round
        crownPath.move(to: NSPoint(x: 9, y: 15.2))
        crownPath.line(to: NSPoint(x: 9, y: 13.8))
        crownPath.stroke()

        let sideButton = NSBezierPath()
        sideButton.lineWidth = 1.4
        sideButton.lineCapStyle = .round
        sideButton.move(to: NSPoint(x: 12.9, y: 13.2))
        sideButton.line(to: NSPoint(x: 14.2, y: 14.4))
        sideButton.stroke()

        if isRunning {
            let progressDot = NSBezierPath(ovalIn: NSRect(x: 11.6, y: 10.8, width: 2.5, height: 2.5))
            progressDot.fill()
        } else {
            let hourHand = NSBezierPath()
            hourHand.lineWidth = 1.6
            hourHand.lineCapStyle = .round
            hourHand.move(to: NSPoint(x: 9, y: 8))
            hourHand.line(to: NSPoint(x: 9, y: 11))
            hourHand.stroke()

            let minuteHand = NSBezierPath()
            minuteHand.lineWidth = 1.6
            minuteHand.lineCapStyle = .round
            minuteHand.move(to: NSPoint(x: 9, y: 8))
            minuteHand.line(to: NSPoint(x: 11.4, y: 6.6))
            minuteHand.stroke()
        }

        let centerDot = NSBezierPath(ovalIn: NSRect(x: 8.1, y: 7.1, width: 1.8, height: 1.8))
        centerDot.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
