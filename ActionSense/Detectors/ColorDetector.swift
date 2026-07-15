import AppKit

// MARK: - 颜色值检测器

final class ColorDetector: ContentDetecting {
    let identifier = "color"; let priority = 0

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        // hex: #RGB / #RRGGBB / #RRGGBBAA
        let hex = "^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
        if text.range(of: hex, options: .regularExpression) != nil, let color = colorFromHex(text) {
            return .color(color, text.uppercased())
        }
        // rgb(r,g,b)
        let rgb = "^rgba?\\s*\\(\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*(?:,\\s*([\\d.]+))?\\s*\\)$"
        guard let regex = try? NSRegularExpression(pattern: rgb),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 4 else { return nil }
        let rStr = String(text[Range(match.range(at: 1), in: text)!])
        let gStr = String(text[Range(match.range(at: 2), in: text)!])
        let bStr = String(text[Range(match.range(at: 3), in: text)!])
        guard let r = Int(rStr), let g = Int(gStr), let b = Int(bStr),
              r <= 255, g <= 255, b <= 255 else { return nil }
        let nsColor = NSColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
        let hexStr = String(format: "#%02X%02X%02X", r, g, b)
        return .color(nsColor, hexStr)
    }

    private func colorFromHex(_ hex: String) -> NSColor? {
        var h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        guard h.count == 6 || h.count == 8, let v = UInt64(h, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if h.count == 8 {
            r = CGFloat((v >> 24) & 0xFF)/255; g = CGFloat((v >> 16) & 0xFF)/255
            b = CGFloat((v >> 8) & 0xFF)/255; a = CGFloat(v & 0xFF)/255
        } else {
            r = CGFloat((v >> 16) & 0xFF)/255; g = CGFloat((v >> 8) & 0xFF)/255
            b = CGFloat(v & 0xFF)/255; a = 1
        }
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
}
