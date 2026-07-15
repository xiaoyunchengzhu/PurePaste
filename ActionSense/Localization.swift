import Foundation
import AppKit

// MARK: - 本地化：String Catalog (Localizable.xcstrings) + 手动语言切换

/// 语言管理器：切换语言后触发 UI 刷新，重启后完整生效
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// 任何语言变更都会改变此值，触发 SwiftUI 重渲染
    @Published var refreshToken = UUID()

    enum Language: String, CaseIterable {
        case auto, english, chinese, japanese, french, german

        var displayName: String {
            switch self {
            case .auto:    return LanguageManager.isChineseSystem ? "自动 (中文)" : "Auto"
            case .english: return "English"
            case .chinese: return "中文"
            case .japanese: return "日本語"
            case .french:   return "Français"
            case .german:   return "Deutsch"
            }
        }

        var appleLanguageCode: String? {
            switch self {
            case .auto:      return nil
            case .english:   return "en"
            case .chinese:   return "zh-Hans"
            case .japanese:  return "ja"
            case .french:    return "fr"
            case .german:    return "de"
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
            refreshToken = UUID() // 触发 UI 即时刷新
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
        case "chinese": return true
        case "english", "japanese", "french", "german": return false
        default: return isChineseSystem
        }
    }

    /// 当前语言代码（zh-Hans / ja / fr / de / en）
    nonisolated static var currentLanguage: String {
        let raw = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "auto"
        switch raw {
        case "chinese":  return "zh-Hans"
        case "japanese": return "ja"
        case "french":   return "fr"
        case "german":   return "de"
        case "english":  return "en"
        default:         return isChineseSystem ? "zh-Hans" : "en"
        }
    }

    /// 系统是否中文（只看第一个 preferredLanguage）
    nonisolated private static var isChineseSystem: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }
}

// MARK: - 本地化文案枚举（API 向后兼容，内部使用 String(localized:)）

enum L10n {

    static var isChinese: Bool { LanguageManager.isChinese }

    /// 多语言翻译：直接根据 preferredLanguage 返回对应文本，不依赖系统的 String(localized:)
    static func loc(_ key: String, zh: String, en: String, ja: String? = nil, fr: String? = nil, de: String? = nil) -> String {
        switch LanguageManager.currentLanguage {
        case "zh-Hans": return zh
        case "ja":      return ja ?? en
        case "fr":      return fr ?? en
        case "de":      return de ?? en
        default:        return en
        }
    }

    enum Mode {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "disabled":  return loc("mode.disabled", zh: "停用", en: "Disabled", ja: "無効", fr: "Désactivé", de: "Deaktiviert")
            case "plainText": return loc("mode.plainText", zh: "纯文本模式", en: "Plain Text", ja: "プレーンテキスト", fr: "Texte brut", de: "Nur Text")
            case "pasteFlow": return loc("mode.pasteFlow", zh: "PasteFlow", en: "PasteFlow", ja: "PasteFlow", fr: "PasteFlow", de: "PasteFlow")
            default:          return rawValue
            }
        }
    }

    enum Detected {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "url":       return loc("type.url", zh: "链接", en: "URL", ja: "URL", fr: "URL", de: "URL")
            case "email":     return loc("type.email", zh: "邮箱", en: "Email", ja: "メール", fr: "Email", de: "E-Mail")
            case "phone":     return loc("type.phone", zh: "电话", en: "Phone", ja: "電話", fr: "Téléphone", de: "Telefon")
            case "datetime":  return loc("type.datetime", zh: "日期时间", en: "Date & Time", ja: "日時", fr: "Date & Heure", de: "Datum & Zeit")
            case "color":     return loc("type.color", zh: "颜色值", en: "Color", ja: "色", fr: "Couleur", de: "Farbe")
            case "imageURL":  return loc("type.imageURL", zh: "图片链接", en: "Image URL", ja: "画像URL", fr: "URL d'image", de: "Bild-URL")
            case "math":      return loc("type.math", zh: "数学计算", en: "Math", ja: "計算", fr: "Maths", de: "Mathe")
            case "geo":       return loc("type.geo", zh: "经纬度", en: "Coordinates", ja: "座標", fr: "Coordonnées", de: "Koordinaten")
            case "richHTML":  return loc("type.richHTML", zh: "富文本", en: "Rich Text", ja: "リッチテキスト", fr: "Texte enrichi", de: "Rich Text")
            case "json":      return loc("type.json", zh: "JSON", en: "JSON", ja: "JSON", fr: "JSON", de: "JSON")
            default:          return rawValue
            }
        }
    }

    enum Action {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "openBrowser":       return loc("action.openBrowser", zh: "浏览器打开", en: "Open in Browser", ja: "ブラウザで開く", fr: "Ouvrir dans le navigateur", de: "Im Browser öffnen")
            case "copyContent":       return loc("action.copyContent", zh: "复制内容", en: "Copy", ja: "コピー", fr: "Copier", de: "Kopieren")
            case "openMail":          return loc("action.openMail", zh: "写邮件", en: "Compose Email", ja: "メール作成", fr: "Écrire un email", de: "E-Mail verfassen")
            case "callPhone":         return loc("action.callPhone", zh: "拨打电话", en: "Call", ja: "電話をかける", fr: "Appeler", de: "Anrufen")
            case "addToCalendar":     return loc("action.addToCalendar", zh: "添加到日历", en: "Add to Calendar", ja: "カレンダーに追加", fr: "Ajouter au calendrier", de: "Zum Kalender hinzufügen")
            case "copyColorHex":      return loc("action.copyColorHex", zh: "复制 HEX", en: "Copy HEX", ja: "HEXをコピー", fr: "Copier HEX", de: "HEX kopieren")
            case "copyColorRGB":      return loc("action.copyColorRGB", zh: "复制 RGB", en: "Copy RGB", ja: "RGBをコピー", fr: "Copier RGB", de: "RGB kopieren")
            case "copyResult":        return loc("action.copyResult", zh: "复制结果", en: "Copy Result", ja: "結果をコピー", fr: "Copier le résultat", de: "Ergebnis kopieren")
            case "openMapLocation":   return loc("action.openMapLocation", zh: "地图定位", en: "Open in Maps", ja: "マップで開く", fr: "Ouvrir dans Plans", de: "In Karten öffnen")
            case "convertToMarkdown": return loc("action.convertToMarkdown", zh: "转为 Markdown", en: "Convert to Markdown", ja: "Markdownに変換", fr: "Convertir en Markdown", de: "In Markdown konvertieren")
            case "convertToPlainText": return loc("action.convertToPlainText", zh: "转为纯文本", en: "Convert to Plain Text", ja: "プレーンテキストに変換", fr: "Convertir en texte brut", de: "In Text konvertieren")
            case "formatJSON":        return loc("action.formatJSON", zh: "格式化", en: "Format", ja: "フォーマット", fr: "Formater", de: "Formatieren")
            case "minifyJSON":        return loc("action.minifyJSON", zh: "压缩", en: "Minify", ja: "縮小", fr: "Minifier", de: "Komprimieren")
            case "openRepo":          return loc("action.openRepo", zh: "打开仓库", en: "Open Repo", ja: "リポジトリを開く", fr: "Ouvrir le dépôt", de: "Repo öffnen")
            default:                  return rawValue
            }
        }
    }

    enum Menu {
        static func text(for rawValue: String) -> String {
            switch rawValue {
            case "modeSelection":    return loc("menu.modeSelection", zh: "模式选择", en: "Mode", ja: "モード", fr: "Mode", de: "Modus")
            case "recentConversion": return loc("menu.recentConversion", zh: "最近转换", en: "Recent", ja: "最近", fr: "Récent", de: "Kürzlich")
            case "preferences":      return loc("menu.preferences", zh: "偏好设置", en: "Preferences", ja: "設定", fr: "Préférences", de: "Einstellungen")
            case "launchAtLogin":    return loc("menu.launchAtLogin", zh: "开机启动", en: "Launch at Login", ja: "ログイン時に起動", fr: "Lancer à l'ouverture", de: "Beim Anmelden starten")
            case "clipboardHistory": return loc("menu.clipboardHistory", zh: "剪贴板历史", en: "Clipboard History", ja: "クリップボード履歴", fr: "Historique", de: "Zwischenablage")
            case "help":             return loc("menu.help", zh: "使用帮助", en: "Help", ja: "ヘルプ", fr: "Aide", de: "Hilfe")
            case "about":            return loc("menu.about", zh: "关于 ActionSense", en: "About ActionSense", ja: "ActionSenseについて", fr: "À propos", de: "Über ActionSense")
            case "quit":             return loc("menu.quit", zh: "退出 ActionSense", en: "Quit ActionSense", ja: "ActionSenseを終了", fr: "Quitter ActionSense", de: "ActionSense beenden")
            case "waitingFirstCopy": return loc("menu.waitingFirstCopy", zh: "等待首次复制...", en: "Waiting for first copy...", ja: "最初のコピーを待っています...", fr: "En attente...", de: "Warte auf erste Kopie...")
            case "lastCopyNonText":  return loc("menu.lastCopyNonText", zh: "上次复制的内容非文本，已忽略", en: "Last copy was non-text, ignored", ja: "前回はテキスト以外のため無視", fr: "Dernière copie non textuelle, ignorée", de: "Kein Text, ignoriert")
            case "trialExpired":     return loc("menu.trialExpired", zh: "试用期已结束，请购买以解锁全部功能", en: "Trial expired. Purchase to unlock.", ja: "試用期間が終了しました。購入してロックを解除してください。", fr: "Période d'essai expirée. Achetez pour débloquer.", de: "Testphase abgelaufen. Kaufen um freizuschalten.")
            case "trialActive":      return loc("menu.trialActive", zh: "试用中", en: "Trial", ja: "お試し中", fr: "Essai", de: "Testphase")
            case "buyActivate":      return loc("menu.buyActivate", zh: "购买激活", en: "Buy Activation", ja: "購入して有効化", fr: "Acheter l'activation", de: "Aktivierung kaufen")
            case "simulateActivate": return loc("menu.simulateActivate", zh: "模拟激活 (Debug)", en: "Simulate Activate (Debug)", ja: "アクティベーションをシミュレート (Debug)", fr: "Simuler l'activation (Debug)", de: "Aktivierung simulieren (Debug)")
            case "cancelActivate":   return loc("menu.cancelActivate", zh: "取消激活 (Debug)", en: "Deactivate (Debug)", ja: "アクティベーション解除 (Debug)", fr: "Désactiver (Debug)", de: "Deaktivieren (Debug)")
            case "version":          return loc("menu.version", zh: "版本 2.0", en: "Version 2.0", ja: "バージョン 2.0", fr: "Version 2.0", de: "Version 2.0")
            default:                 return rawValue
            }
        }
    }

    // Big text blocks
    static var aboutTitle: String { "ActionSense" }
    static var helpTitle: String { loc("help.title", zh: "ActionSense 使用帮助", en: "ActionSense Help", ja: "ActionSense ヘルプ", fr: "Aide ActionSense", de: "ActionSense Hilfe") }
    static var helpText: String { loc("help.text", zh: L10n._helpZh, en: L10n._helpEn) }
    static var helpButton: String { loc("help.button", zh: "知道了", en: "Got it", ja: "了解", fr: "Compris", de: "Verstanden") }
    static var aboutText: String { loc("about.text", zh: L10n._aboutZh, en: L10n._aboutEn) }
    static var aboutOK: String { loc("about.ok", zh: "确定", en: "OK", ja: "OK", fr: "OK", de: "OK") }
    static var startupMessage: String { loc("startup.message", zh: "🔵 蓝色 = 纯文本 | 🩵 青色 = PasteFlow | ⚫ 灰色 = 停用", en: "🔵 Blue = Plain Text | 🩵 Teal = PasteFlow | ⚫ Gray = Disabled", ja: "🔵 青 = テキスト | 🩵 水色 = PasteFlow | ⚫ 灰色 = 無効", fr: "🔵 Bleu = Texte | 🩵 Cyan = PasteFlow | ⚫ Gris = Désactivé", de: "🔵 Blau = Text | 🩵 Türkis = PasteFlow | ⚫ Grau = Deaktiviert") }
    static var calendarEventTitle: String { loc("calendar.title", zh: "来自剪贴板", en: "From Clipboard", ja: "クリップボードから", fr: "Du presse-papiers", de: "Aus der Zwischenablage") }
    static var proRemaining: String { loc("pro.remaining", zh: "今日剩余 %d 次 PasteFlow", en: "%d PasteFlow remaining today", ja: "本日残り %d 回", fr: "%d utilisations restantes aujourd'hui", de: "Noch %d heute") }
    static var proDebugOn: String { loc("pro.debugOn", zh: "取消 Pro (Debug)", en: "Deactivate Pro (Debug)", ja: "Pro解除 (Debug)", fr: "Désactiver Pro (Debug)", de: "Pro deaktivieren (Debug)") }

    static var historySearchPlaceholder: String { loc("history.search", zh: "搜索历史...", en: "Search history...", ja: "履歴を検索...", fr: "Rechercher...", de: "Verlauf durchsuchen...") }
    static var historyEmpty: String { loc("history.empty", zh: "暂无历史记录", en: "No history yet", ja: "履歴はまだありません", fr: "Aucun historique", de: "Noch kein Verlauf") }
    static var historyNoMatch: String { loc("history.noMatch", zh: "未找到匹配项", en: "No matching entries", ja: "一致する項目なし", fr: "Aucune correspondance", de: "Keine Einträge") }
    static var historyCopyText: String { loc("history.copyText", zh: "复制文本", en: "Copy Text", ja: "テキストをコピー", fr: "Copier le texte", de: "Text kopieren") }
    static var historyDeleteEntry: String { loc("history.deleteEntry", zh: "删除此记录", en: "Delete Entry", ja: "この記録を削除", fr: "Supprimer", de: "Eintrag löschen") }
    static var historyNotActed: String { loc("history.notActed", zh: "未操作", en: "Not acted", ja: "未操作", fr: "Non traité", de: "Nicht ausgeführt") }
    static var historyClearAll: String { loc("history.clearAll", zh: "清除全部", en: "Clear All", ja: "すべて削除", fr: "Tout effacer", de: "Alle löschen") }
    static var historyEntriesLabel: String { loc("history.entries", zh: "条", en: "entries", ja: "件", fr: "entrées", de: "Einträge") }
    static var historyTitle: String { loc("history.title", zh: "ActionSense 剪贴板历史", en: "ActionSense Clipboard History", ja: "ActionSense クリップボード履歴", fr: "Historique ActionSense", de: "ActionSense Zwischenablage") }

    static var calendarTime: String { loc("calendar.time", zh: "时间", en: "Time", ja: "時間", fr: "Heure", de: "Zeit") }
    static var calendarOriginal: String { loc("calendar.original", zh: "原始内容", en: "Original", ja: "元の内容", fr: "Original", de: "Original") }
    static var languageLabel: String { loc("menu.language", zh: "语言", en: "Language", ja: "言語", fr: "Langue", de: "Sprache") }
    static var languageRestartTitle: String { loc("language.restartTitle", zh: "语言已更改", en: "Language Changed", ja: "言語が変更されました", fr: "Langue modifiée", de: "Sprache geändert") }
    static var languageRestartNow: String { loc("language.restartNow", zh: "立即重启", en: "Restart Now", ja: "今すぐ再起動", fr: "Redémarrer", de: "Jetzt neustarten") }
    static var languageRestartLater: String { loc("language.restartLater", zh: "稍后", en: "Later", ja: "後で", fr: "Plus tard", de: "Später") }
    static var languageRestartMsg: String { loc("language.restartMsg", zh: "请重启 ActionSense 使语言设置生效。", en: "Please restart ActionSense for the language change to take effect.", ja: "再起動して言語変更を反映してください。", fr: "Redémarrez ActionSense pour appliquer.", de: "Starten Sie ActionSense neu.") }
    static var proTitle: String { loc("pro.title", zh: "ActionSense Pro", en: "ActionSense Pro", ja: "ActionSense Pro", fr: "ActionSense Pro", de: "ActionSense Pro") }
    static var proUpgrade: String { loc("pro.upgrade", zh: "升级 Pro · 无限次", en: "Upgrade to Pro · Unlimited", ja: "Proにアップグレード · 無制限", fr: "Passer à Pro · Illimité", de: "Pro Upgrade · Unbegrenzt") }
    static var proRestore: String { loc("pro.restore", zh: "恢复购买", en: "Restore Purchase", ja: "購入を復元", fr: "Restaurer l'achat", de: "Kauf wiederherstellen") }
    static var proError: String { loc("pro.error", zh: "产品信息加载失败，请稍后重试", en: "Failed to load product, please try later", ja: "製品情報の読み込みに失敗しました", fr: "Échec du chargement, réessayez", de: "Laden fehlgeschlagen, bitte später versuchen") }
    static var proDebugOff: String { loc("pro.debugOff", zh: "模拟 Pro (Debug)", en: "Simulate Pro (Debug)", ja: "Proをシミュレート (Debug)", fr: "Simuler Pro (Debug)", de: "Pro simulieren (Debug)") }

    // Large text fallbacks
    private static let _aboutZh = "macOS 智能剪贴板助手。\n纯文本净化 + PasteFlow 智能识别 + 意图历史回溯。\n\n隐私声明：\n所有处理均在本地完成，数据永不上传。\n\n反馈：https://github.com/xiaoyunchengzhu/ActionSense/issues\n作者：xiaoniubuniu.com"
    private static let _aboutEn = "macOS smart clipboard assistant.\nPlain text purification + PasteFlow intent detection + intent history.\n\nPrivacy: All processing is local. Your data never leaves this machine.\n\nFeedback: https://github.com/xiaoyunchengzhu/ActionSense/issues\nAuthor: xiaoniubuniu.com"
    private static let _helpZh = "模式说明：\n🔵 纯文本模式 — 自动剥离复制内容的富文本格式，清理多余空白和 CJK 空格，写回剪贴板\n🩵 PasteFlow   — 智能识别复制内容类型，在鼠标旁弹出操作面板，一键直达\n\nPasteFlow 识别类型：\nURL / 邮箱 / 电话 / 地址 / IP / 日期\n颜色值 / 数学算式 / 经纬度 / 快递单号 / JSON\n\n操作提示：\n· 面板仅一个按钮时，按 Enter 直接触发\n· 按 ESC 或点击面板外部关闭面板\n· 菜单栏图标颜色随模式变化，一眼知状态\n\n历史记录：\n· 点击菜单「剪贴板历史」打开独立窗口\n· 🟢 意图完成  🟠 识别未操作  ⚪ 普通复制\n· 支持按类型、模式、关键词筛选\n\n隐私声明：所有处理均在本地完成，数据永不上传。\n问题反馈：https://github.com/xiaoyunchengzhu/ActionSense/issues\n作者网站：https://www.xiaoniubuniu.com"
    private static let _helpEn = "Modes:\n🔵 Plain Text — Auto strip formatting, clean whitespace & CJK spacing\n🩵 PasteFlow  — Detect content type, pop up action panel near cursor\n\nPasteFlow Detection:\nURL / Email / Phone / Address / IP / Date\nColor / Math / Coordinates / Tracking / Rich HTML / JSON\n\nTips:\n· Press Enter to trigger when only one action is shown\n· Press ESC or click outside to dismiss the panel\n· Menu bar icon color reflects current mode\n\nHistory:\n· Click \"Clipboard History\" in the menu to open\n· 🟢 Fulfilled  🟠 Detected  ⚪ Plain\n· Filter by type, mode, or keyword\n\nPrivacy: All processing is local. Your data never leaves this machine.\nFeedback: https://github.com/xiaoyunchengzhu/ActionSense/issues\nAuthor: https://www.xiaoniubuniu.com"
    // Confirm clear dialog
    static var confirmClearTitle: String { loc("confirm.clear.title", zh: "确认清除", en: "Confirm Clear", ja: "削除の確認", fr: "Confirmer la suppression", de: "Löschen bestätigen") }
    static var confirmClearCancel: String { loc("confirm.clear.cancel", zh: "取消", en: "Cancel", ja: "キャンセル", fr: "Annuler", de: "Abbrechen") }
    static var confirmClearOK: String { loc("confirm.clear.ok", zh: "清除全部", en: "Clear All", ja: "すべて削除", fr: "Tout effacer", de: "Alle löschen") }
    static func confirmClearMsg(_ count: Int) -> String {
        let fmt = loc("confirm.clear.msg", zh: "确定要清除全部 %d 条历史记录吗？此操作不可撤销。", en: "Are you sure you want to clear all %d entries? This cannot be undone.", ja: "%d 件の履歴をすべて削除しますか？この操作は元に戻せません。", fr: "Supprimer les %d entrées ? Cette action est irréversible.", de: "Alle %d Einträge löschen? Dies kann nicht rückgängig gemacht werden.")
        return String(format: fmt, count)
    }
}


// Extend HistoryStore.FilterMode for localization
extension HistoryStore.FilterMode {
    var localizedName: String {
        switch self {
        case .all:             return L10n.loc("history.filter.all", zh: "全部", en: "All", ja: "すべて", fr: "Tout", de: "Alle")
        case .intentFulfilled: return L10n.loc("history.filter.fulfilled", zh: "意图", en: "Fulfilled", ja: "完了", fr: "Terminé", de: "Erledigt")
        case .detectedOnly:    return L10n.loc("history.filter.detected", zh: "识别", en: "Detected", ja: "検出", fr: "Détecté", de: "Erkannt")
        case .unrecognized:    return L10n.loc("history.filter.other", zh: "未识别", en: "Other", ja: "その他", fr: "Autre", de: "Andere")
        case .plainText:       return L10n.loc("history.filter.plain", zh: "纯文本", en: "Plain", ja: "テキスト", fr: "Texte", de: "Text")
        }
    }
}
