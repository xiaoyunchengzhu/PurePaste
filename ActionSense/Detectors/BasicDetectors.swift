import Foundation
import AppKit

// MARK: - 基础检测器（URL / Email / Phone / IP / ImageURL）

final class URLDetector: ContentDetecting {
    let identifier = "url"; let priority = 3

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        guard let url = URL(string: text), let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              url.host?.contains(".") == true else {
            if text.hasPrefix("www."), let url = URL(string: "https://\(text)") { return .url(url) }
            return nil
        }
        return .url(url)
    }
}

final class EmailDetector: ContentDetecting {
    let identifier = "email"; let priority = 2

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let pattern = "^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$"
        guard text.range(of: pattern, options: .regularExpression) != nil else { return nil }
        return .email(text)
    }
}

final class PhoneDetector: ContentDetecting {
    let identifier = "phone"; let priority = 5

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let cleaned = text.replacingOccurrences(of: "[\\- ]", with: "", options: .regularExpression)
        guard cleaned.range(of: "^(\\+?86)?1[3-9]\\d{9}$", options: .regularExpression) != nil else { return nil }
        let digits = cleaned.replacingOccurrences(of: "^(\\+?86)", with: "", options: .regularExpression).filter { $0.isNumber }
        guard digits.count == 11 else { return nil }
        let s = Array(digits)
        return .phone("\(s[0])\(s[1])\(s[2]) \(s[3])\(s[4])\(s[5])\(s[6]) \(s[7])\(s[8])\(s[9])\(s[10])")
    }
}

final class IPDetector: ContentDetecting {
    let identifier = "ip"; let priority = 1

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let pattern = "^((25[0-5]|2[0-4]\\d|1\\d{2}|[1-9]?\\d)\\.){3}(25[0-5]|2[0-4]\\d|1\\d{2}|[1-9]?\\d)$"
        guard text.range(of: pattern, options: .regularExpression) != nil else { return nil }
        return .ipAddress(text)
    }
}

final class ImageURLDetector: ContentDetecting {
    let identifier = "imageURL"; let priority = 4

    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        let exts = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".svg", ".heic", ".avif"]
        let lower = text.lowercased()
        guard exts.contains(where: { lower.hasSuffix($0) || lower.contains("\($0)?") }),
              let url = URL(string: text), url.scheme != nil else { return nil }
        return .imageURL(url)
    }
}
