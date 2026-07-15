import Foundation

// MARK: - 剪贴板历史条目

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    let mode: String           // plainText / pasteFlow
    let detectedType: String?   // PasteFlow 识别类型名，nil = 未识别
    let action: String?         // 用户执行的操作名，nil = 未操作
    let isIntentFulfilled: Bool // 是否完成了意图动作

    init(text: String, mode: String, detectedType: String?, action: String? = nil, isIntentFulfilled: Bool = false) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.mode = mode
        self.detectedType = detectedType
        self.action = action
        self.isIntentFulfilled = isIntentFulfilled
    }

    /// 用于列表展示的简短预览（前 80 字符，取第一行）
    var preview: String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        return String(firstLine.prefix(80))
    }

    /// 相对时间描述
    var relativeTime: String {
        let interval = Date().timeIntervalSince(timestamp)
        let lang = LanguageManager.currentLanguage
        let m = Int(interval / 60)
        let h = Int(interval / 3600)
        let d = Int(interval / 86400)
        switch interval {
        case ..<60:
            switch lang {
            case "zh-Hans": return "刚刚"
            case "ja":      return "たった今"
            case "fr":      return "à l'instant"
            case "de":      return "gerade eben"
            default:        return "just now"
            }
        case ..<3600:
            switch lang {
            case "zh-Hans": return "\(m) 分钟前"
            case "ja":      return "\(m) 分前"
            case "fr":      return "il y a \(m) min"
            case "de":      return "vor \(m) Min"
            default:        return "\(m)m ago"
            }
        case ..<86400:
            switch lang {
            case "zh-Hans": return "\(h) 小时前"
            case "ja":      return "\(h) 時間前"
            case "fr":      return "il y a \(h) h"
            case "de":      return "vor \(h) Std"
            default:        return "\(h)h ago"
            }
        default:
            switch lang {
            case "zh-Hans": return "\(d) 天前"
            case "ja":      return "\(d) 日前"
            case "fr":      return "il y a \(d) j"
            case "de":      return "vor \(d) Tagen"
            default:        return "\(d)d ago"
            }
        }
    }
}
