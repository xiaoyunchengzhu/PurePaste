import Foundation
import AppKit

// MARK: - 本地化：String Catalog (Localizable.xcstrings) + 手动语言切换

/// 语言管理器：切换语言后需重启生效
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    enum Language: String, CaseIterable {
        case auto, english, chinese

        var displayName: String {
            let zh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
            switch self {
            case .auto:    return zh
                ? String(localized: "language.auto.zh")
                : String(localized: "language.auto.en")
            case .english: return String(localized: "language.english")
            case .chinese: return String(localized: "language.chinese")
            }
        }

        var appleLanguageCode: String? {
            switch self {
            case .auto:    return nil
            case .english: return "en"
            case .chinese: return "zh-Hans"
            }
        }
    }

    /// 用户偏好语言
    var preferredLanguage: Language {
        get {
            Language(rawValue: UserDefaults.standard.string(forKey: "preferredLanguage") ?? "auto") ?? .auto
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "preferredLanguage")
            applyLanguage(newValue)
        }
    }

    private init() {}

    /// 应用语言设置
    private func applyLanguage(_ lang: Language) {
        if let code = lang.appleLanguageCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    /// 应用启动时调用，确保 AppleLanguages 与 preference 一致
    func syncOnLaunch() {
        applyLanguage(preferredLanguage)
    }

    /// 重启 App
    func restart() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", Bundle.main.bundlePath]
        task.launch()
        NSApp.terminate(nil)
    }

    /// 当前是否中文（用于非 UI 逻辑的判断）
    nonisolated static var isChinese: Bool {
        let raw = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "auto"
        switch raw {
        case "zh": return true
        case "en": return false
        default:  return Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
        }
    }

    nonisolated private static var isChineseSystem: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }
}

// MARK: - 本地化文案枚举（API 向后兼容，内部使用 String(localized:)）

enum L10n {

    static var isChinese: Bool { LanguageManager.isChinese }

    /// String(localized:) 的带降级版本：如果返回的是 key 本身（xcstrings 未加载），使用硬编码值
    private static func loc(_ key: String, zh: String, en: String) -> String {
        let result = String(localized: String.LocalizationValue(key))
        // If localization returned the key itself, fallback
        if result == key {
            return isChinese ? zh : en
        }
        return result
    }

    enum Mode {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "disabled":  return loc("mode.disabled", zh: "停用", en: "Disabled")
            case "plainText": return loc("mode.plainText", zh: "纯文本模式", en: "Plain Text")
            case "pasteFlow": return loc("mode.pasteFlow", zh: "PasteFlow", en: "PasteFlow")
            default:          return rawValue
            }
        }
    }

    enum Detected {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "url":       return loc("type.url", zh: "链接", en: "URL")
            case "email":     return loc("type.email", zh: "邮箱", en: "Email")
            case "phone":     return loc("type.phone", zh: "电话", en: "Phone")
            case "address":   return loc("type.address", zh: "地址", en: "Address")
            case "datetime":  return loc("type.datetime", zh: "日期时间", en: "Date & Time")
            case "ip":        return loc("type.ip", zh: "IP 地址", en: "IP Address")
            case "tracking":  return loc("type.tracking", zh: "快递单号", en: "Tracking")
            case "color":     return loc("type.color", zh: "颜色值", en: "Color")
            case "imageURL":  return loc("type.imageURL", zh: "图片链接", en: "Image URL")
            case "math":      return loc("type.math", zh: "数学计算", en: "Math")
            case "geo":       return loc("type.geo", zh: "经纬度", en: "Coordinates")
            case "richHTML":  return loc("type.richHTML", zh: "富文本", en: "Rich Text")
            case "json":      return loc("type.json", zh: "JSON", en: "JSON")
            default:          return rawValue
            }
        }
    }

    enum Action {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "openBrowser":       return loc("action.openBrowser", zh: "浏览器打开", en: "Open in Browser")
            case "copyContent":       return loc("action.copyContent", zh: "复制内容", en: "Copy")
            case "openMail":          return loc("action.openMail", zh: "写邮件", en: "Compose Email")
            case "callPhone":         return loc("action.callPhone", zh: "拨打电话", en: "Call")
            case "openMaps":          return loc("action.openMaps", zh: "地图查看", en: "Open in Maps")
            case "addToCalendar":     return loc("action.addToCalendar", zh: "添加到日历", en: "Add to Calendar")
            case "pingIP":            return loc("action.pingIP", zh: "Ping", en: "Ping")
            case "trackPackage":      return loc("action.trackPackage", zh: "查快递", en: "Track Package")
            case "copyColorHex":      return loc("action.copyColorHex", zh: "复制 HEX", en: "Copy HEX")
            case "copyColorRGB":      return loc("action.copyColorRGB", zh: "复制 RGB", en: "Copy RGB")
            case "copyResult":        return loc("action.copyResult", zh: "复制结果", en: "Copy Result")
            case "openMapLocation":   return loc("action.openMapLocation", zh: "地图定位", en: "Open in Maps")
            case "convertToMarkdown": return loc("action.convertToMarkdown", zh: "转为 Markdown", en: "Convert to Markdown")
            case "convertToPlainText": return loc("action.convertToPlainText", zh: "转为纯文本", en: "Convert to Plain Text")
            case "formatJSON":        return loc("action.formatJSON", zh: "格式化", en: "Format")
            case "minifyJSON":        return loc("action.minifyJSON", zh: "压缩", en: "Minify")
            case "openRepo":          return loc("action.openRepo", zh: "打开仓库", en: "Open Repo")
            default:                  return rawValue
            }
        }
    }

    enum Menu {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "modeSelection":    return String(localized: "menu.modeSelection")
            case "recentConversion": return String(localized: "menu.recentConversion")
            case "preferences":      return String(localized: "menu.preferences")
            case "launchAtLogin":    return String(localized: "menu.launchAtLogin")
            case "clipboardHistory": return String(localized: "menu.clipboardHistory")
            case "help":             return String(localized: "menu.help")
            case "about":            return String(localized: "menu.about")
            case "quit":             return String(localized: "menu.quit")
            case "waitingFirstCopy": return String(localized: "menu.waitingFirstCopy")
            case "lastCopyNonText":  return String(localized: "menu.lastCopyNonText")
            case "trialExpired":     return String(localized: "menu.trialExpired")
            case "trialActive":      return String(localized: "menu.trialActive")
            case "buyActivate":      return String(localized: "menu.buyActivate")
            case "simulateActivate": return String(localized: "menu.simulateActivate")
            case "cancelActivate":   return String(localized: "menu.cancelActivate")
            case "version":          return String(localized: "menu.version")
            default:                 return rawValue
            }
        }
    }

    // Big text blocks
    static var aboutTitle: String { "ActionSense" }
    static var helpTitle: String { String(localized: "help.title") }
    static var helpText: String { String(localized: "help.text") }
    static var helpButton: String { String(localized: "help.button") }
    static var aboutText: String { String(localized: "about.text") }
    static var aboutOK: String { String(localized: "about.ok") }
    static var startupMessage: String { String(localized: "startup.message") }
    static var calendarEventTitle: String { String(localized: "calendar.title") }
}


// Extend HistoryStore.FilterMode for localization
extension HistoryStore.FilterMode {
    var localizedName: String {
        switch self {
        case .all:             return String(localized: "history.filter.all")
        case .intentFulfilled: return String(localized: "history.filter.fulfilled")
        case .detectedOnly:    return String(localized: "history.filter.detected")
        case .unrecognized:    return String(localized: "history.filter.other")
        case .plainText:       return String(localized: "history.filter.plain")
        }
    }
}
