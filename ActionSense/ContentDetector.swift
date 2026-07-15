import Foundation
import AppKit

// MARK: - 内容识别结果

/// PasteFlow 识别到的内容类型，携带解析后的数据
enum DetectedContent {
    case url(URL)
    case email(String)
    case phone(String)
    case datetime(Date, String)
        case color(NSColor, String)
    case imageURL(URL)
    case mathExpression(String, Double)
    case geoCoordinate(Double, Double)
    case richHTML(String, Data)  // (plainText, htmlData)
    case jsonContent(String)     // validated JSON string

    /// 类型展示名称
    var displayType: String {
        switch self {
        case .url:             return L10n.Detected.text(for: "url")
        case .email:           return L10n.Detected.text(for: "email")
        case .phone:           return L10n.Detected.text(for: "phone")
        case .datetime:        return L10n.Detected.text(for: "datetime")
        case .color:           return L10n.Detected.text(for: "color")
        case .imageURL:        return L10n.Detected.text(for: "imageURL")
        case .mathExpression:  return L10n.Detected.text(for: "math")
        case .geoCoordinate:   return L10n.Detected.text(for: "geo")
        case .richHTML:        return L10n.Detected.text(for: "richHTML")
        case .jsonContent:     return L10n.Detected.text(for: "json")
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .url:             return "link"
        case .email:           return "envelope"
        case .phone:           return "phone"
        case .datetime:        return "calendar"
        case .color:           return "paintpalette"
        case .imageURL:        return "photo"
        case .mathExpression:  return "function"
        case .geoCoordinate:   return "location.fill"
        case .richHTML:        return "doc.richtext"
        case .jsonContent:     return "curlybraces"
        }
    }

    /// 原始文本摘要（用于面板预览）
    var previewText: String {
        switch self {
        case .url(let url):
            return url.absoluteString
        case .email(let addr):
            return addr
        case .phone(let num):
            return num
        case .datetime(_, let original):
            return original
        case .color(_, let hex):
            return hex
        case .imageURL(let url):
            return url.absoluteString
        case .mathExpression(let expr, let result):
            return "\(expr) = \(formatNumber(result))"
        case .geoCoordinate(let lat, let lng):
            return String(format: "%.6f, %.6f", lat, lng)
        case .richHTML(let text, _):
            return String(text.prefix(80))
        case .jsonContent(let text):
            if let data = text.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data),
               let formatted = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
               let result = String(data: formatted, encoding: .utf8) {
                return String(result.prefix(200))
            }
            return String(text.prefix(80))
        }
    }

    /// 格式化数字显示（整数不显示小数点）
    private func formatNumber(_ n: Double) -> String {
        if n == floor(n) && n.isFinite {
            return String(format: "%.0f", n)
        }
        return String(format: "%.6g", n)
    }
}

// MARK: - 可执行的操作

enum PasteFlowAction: CaseIterable {
    case openBrowser
    case openMail
    case callPhone
    case addToCalendar
    case copyColorHex
    case copyColorRGB
    case copyResult
    case openMapLocation
    case convertToMarkdown
    case convertToPlainText
    case formatJSON
    case minifyJSON
    case openRepo

    var displayName: String {
        switch self {
        case .openBrowser:        return L10n.Action.text(for: "openBrowser")
        case .openMail:           return L10n.Action.text(for: "openMail")
        case .callPhone:          return L10n.Action.text(for: "callPhone")
        case .addToCalendar:      return L10n.Action.text(for: "addToCalendar")
        case .copyColorHex:       return L10n.Action.text(for: "copyColorHex")
        case .copyColorRGB:       return L10n.Action.text(for: "copyColorRGB")
        case .copyResult:         return L10n.Action.text(for: "copyResult")
        case .openMapLocation:    return L10n.Action.text(for: "openMapLocation")
        case .convertToMarkdown:  return L10n.Action.text(for: "convertToMarkdown")
        case .convertToPlainText: return L10n.Action.text(for: "convertToPlainText")
        case .formatJSON:        return L10n.Action.text(for: "formatJSON")
        case .minifyJSON:        return L10n.Action.text(for: "minifyJSON")
        case .openRepo:           return L10n.Action.text(for: "openRepo")
        }
    }

    var iconName: String {
        switch self {
        case .openBrowser:        return "safari"
        case .openMail:           return "envelope"
        case .callPhone:          return "phone"
        case .addToCalendar:      return "calendar.badge.plus"
        case .copyColorHex:       return "number"
        case .copyColorRGB:       return "number.square"
        case .copyResult:         return "doc.on.doc"
        case .openMapLocation:    return "location.fill"
        case .convertToMarkdown:  return "arrow.down.doc"
        case .convertToPlainText: return "text.alignleft"
        case .formatJSON:        return "text.alignleft"
        case .minifyJSON:        return "arrow.up.and.down.text.horizontal"
        case .openRepo:           return "terminal"
        }
    }

    /// 每种内容类型对应的一组操作
    static func actions(for content: DetectedContent) -> [PasteFlowAction] {
        switch content {
        case .url(let url):
            var actions: [PasteFlowAction] = [.openBrowser]
            // 检测 git repo URL (github.com/owner/repo 等)
            let host = url.host?.lowercased() ?? ""
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let pathParts = path.components(separatedBy: "/").filter { !$0.isEmpty }
            if ["github.com", "gitlab.com", "bitbucket.org"].contains(where: { host.contains($0) || host == $0 })
               && pathParts.count >= 2 {
                actions.append(.openRepo)
            }
            return actions
        case .email:       return [.openMail]
        case .phone:       return [.callPhone]
        case .datetime:    return [.addToCalendar]
        case .color:           return [.copyColorHex, .copyColorRGB]
        case .imageURL:        return [.openBrowser]
        case .mathExpression:  return [.copyResult]
        case .geoCoordinate:   return [.openMapLocation]
        case .richHTML:        return [.convertToMarkdown, .convertToPlainText]
        case .jsonContent:     return [.formatJSON, .minifyJSON]
        }
    }
}
