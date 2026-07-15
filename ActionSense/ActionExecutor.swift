import AppKit

// MARK: - 操作执行器，处理 PasteFlow 面板中各按钮的实际行为

enum ActionExecutor {

    /// 执行指定操作
    static func execute(action: PasteFlowAction, content: DetectedContent) {
        switch action {
        case .openBrowser:
            openBrowser(for: content)
        case .openMail:
            openMail(for: content)
        case .callPhone:
            callPhone(for: content)
        case .addToCalendar:
            addToCalendar(for: content)
        case .copyColorHex:
            copyColorHex(for: content)
        case .copyColorRGB:
            copyColorRGB(for: content)
        case .copyResult:
            copyResult(for: content)
        case .openMapLocation:
            openMapLocation(for: content)
        case .convertToMarkdown:
            convertToMarkdown(for: content)
        case .convertToPlainText:
            convertToPlainText(for: content)
        case .formatJSON:
            formatJSON(for: content)
        case .minifyJSON:
            minifyJSON(for: content)
        case .openRepo:
            openRepo(for: content)
        }
    }

    // MARK: - 浏览器打开

    private static func openBrowser(for content: DetectedContent) {
        let urlString: String?
        switch content {
        case .url(let url):
            urlString = url.absoluteString
        case .imageURL(let url):
            urlString = url.absoluteString
        default:
            urlString = nil
        }
        guard let str = urlString, let url = URL(string: str) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - 打开邮件客户端

    private static func openMail(for content: DetectedContent) {
        guard case .email(let addr) = content else { return }
        if let url = URL(string: "mailto:\(addr)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 拨打电话

    private static func callPhone(for content: DetectedContent) {
        guard case .phone(let num) = content else { return }
        let digits = num.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 添加到日历

    private static func addToCalendar(for content: DetectedContent) {
        guard case .datetime(let date, let original) = content else { return }

        // 创建日历事件的基本信息写入剪贴板
        // 由于直接写入系统日历需要 EventKit 权限（较复杂），
        // 这里采用将事件详情复制到剪贴板的方式
        let formatter = DateFormatter()
        formatter.locale = L10n.isChinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateFormat = L10n.isChinese ? "yyyy年M月d日 HH:mm" : "MMM d, yyyy HH:mm"

        let info = """
        \(L10n.calendarEventTitle)
        \(L10n.calendarTime)：\(formatter.string(from: date))
        \(L10n.calendarOriginal)：\(original)
        """
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(info, forType: .string)

        // 尝试通过 URL scheme 打开日历快速添加
        // macOS 不支持直接 add-event URL，替代方案是打开日历 App
        if let calendarURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "ical://")!) {
            NSWorkspace.shared.open(calendarURL)
        }
    }

    // MARK: - 复制 HEX

    private static func copyColorHex(for content: DetectedContent) {
        guard case .color(_, let hex) = content else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(hex, forType: .string)
    }

    // MARK: - 复制 RGB

    private static func copyColorRGB(for content: DetectedContent) {
        guard case .color(let color, _) = content else { return }
        let r = Int(color.redComponent * 255)
        let g = Int(color.greenComponent * 255)
        let b = Int(color.blueComponent * 255)
        let rgb = "rgb(\(r), \(g), \(b))"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(rgb, forType: .string)
    }

    // MARK: - 复制计算结果

    private static func copyResult(for content: DetectedContent) {
        guard case .mathExpression(_, let result) = content else { return }
        let text: String
        if result == floor(result) && result.isFinite {
            text = String(format: "%.0f", result)
        } else {
            text = String(format: "%.6g", result)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - 地图定位（经纬度）

    private static func openMapLocation(for content: DetectedContent) {
        guard case .geoCoordinate(let lat, let lng) = content else { return }
        let urlStr = "https://maps.apple.com/?ll=\(lat),\(lng)&q=\(lat),\(lng)"
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 格式转换

    /// HTML / 富文本 → Markdown（使用检测时存储的 HTML 数据，不重新读剪贴板）
    private static func convertToMarkdown(for content: DetectedContent) {
        guard case .richHTML(let text, let htmlData) = content, !htmlData.isEmpty else { return }
        let markdown = TextProcessor.smartMarkdown(htmlData: htmlData, fallbackText: text)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }

    /// 任意内容 → 纯文本
    private static func convertToPlainText(for content: DetectedContent) {
        let text: String
        switch content {
        case .richHTML(let t, _): text = t
        default: text = content.previewText
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(TextProcessor.plainText(text), forType: .string)
    }

    // MARK: - JSON 处理

    private static func formatJSON(for content: DetectedContent) {
        guard case .jsonContent(let json) = content,
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
              let result = String(data: formatted, encoding: .utf8) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(result, forType: .string)
    }

    private static func minifyJSON(for content: DetectedContent) {
        guard case .jsonContent(let json) = content,
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: obj, options: []),
              let result = String(data: compact, encoding: .utf8) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(result, forType: .string)
    }

    // MARK: - Git Repo

    private static func openRepo(for content: DetectedContent) {
        guard case .url(let url) = content else { return }
        let urlStr = url.absoluteString
        // 提取 owner/repo，去掉多余路径
        if urlStr.contains("github.com") || urlStr.contains("gitlab.com") || urlStr.contains("bitbucket.org") {
            // 拼接 repo 页面 URL
            let parts = url.pathComponents.filter { $0 != "/" }
            if parts.count >= 2 {
                let repoPath = parts.prefix(3).joined(separator: "/")  // /owner/repo
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.path = repoPath
                if let repoURL = components?.url {
                    NSWorkspace.shared.open(repoURL)
                    return
                }
            }
        }
        NSWorkspace.shared.open(url)
    }

}
