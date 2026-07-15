import SwiftUI
import AppKit
import ServiceManagement

// MARK: - 工作模式枚举

enum PasteMode: String, CaseIterable {
    case disabled   // 停用
    case plainText  // 纯文本模式
    case pasteFlow  // PasteFlow 智能识别

    var displayName: String { L10n.Mode.text(for: rawValue) }

    var menuBarIcon: String {
        switch self {
        case .disabled:  return "clipboard"
        case .plainText: return "list.clipboard"
        case .pasteFlow: return "sparkles"
        }
    }
}

// MARK: - 核心 ViewModel，管理剪贴板监听、格式纯化和状态

@MainActor
final class ActionSenseViewModel: ObservableObject {

    // MARK: - 依赖（P1: 可通过 init 注入，默认使用 shared）

    private let monitor: ClipboardMonitor
    private let registry: DetectorRegistry
    private let panelController: FloatingPanelController
    private let historyStore: HistoryStore
    let storeManager: StoreManager

    // MARK: - 发布的状态属性

    @Published var mode: PasteMode = .pasteFlow
    @Published var lastConversionPreview: String?
    @Published var conversionCount: Int = 0
    @Published var isProcessing: Bool = false
    @Published var lastCopyWasNonText: Bool = false

    /// 是否开机启动
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { Task { await updateLoginItem() } }
    }

    // MARK: - 初始化

    init(monitor: ClipboardMonitor? = nil,
         registry: DetectorRegistry? = nil,
         panel: FloatingPanelController? = nil,
         history: HistoryStore? = nil,
         storeManager: StoreManager? = nil) {
        self.monitor = monitor ?? ClipboardMonitor()
        self.registry = registry ?? .shared
        self.panelController = panel ?? .shared
        self.historyStore = history ?? .shared
        self.storeManager = storeManager ?? .shared

        self.monitor.onClipboardChange = { [weak self] text, htmlData in
            self?.handleClipboardChange(text: text, htmlData: htmlData)
        }
        self.monitor.start()
        Task { await syncLoginItemState() }
    }

    // MARK: - Pro 状态

    var isPasteFlowAvailable: Bool { storeManager.canUsePasteFlow }
    var remainingDailyCount: Int { storeManager.remainingCount }

    // MARK: - 剪贴板处理

    private func handleClipboardChange(text: String, htmlData: Data?) {
        guard mode != .disabled else { return }

        lastCopyWasNonText = false

        // PasteFlow 模式
        if mode == .pasteFlow, storeManager.canUsePasteFlow {
            isProcessing = true
            if let detected = registry.detect(text, htmlData: htmlData) {
                panelController.onActionExecuted = { [weak self] action in
                    self?.historyStore.markLastIntentFulfilled(action: action.displayName)
                }
                panelController.show(content: detected, at: NSEvent.mouseLocation)
                lastConversionPreview = "[\(detected.displayType)] \(String(detected.previewText.prefix(40)))"
                conversionCount += 1
                storeManager.recordUsage()
                historyStore.addEntry(text: text, mode: "pasteFlow", detectedType: detected.displayType)
            } else {
                historyStore.addEntry(text: text, mode: "pasteFlow", detectedType: nil)
            }
            isProcessing = false
            return
        }

        // 纯文本模式：格式净化后写回剪贴板
        isProcessing = true
        let processed = TextProcessor.plainText(text)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(processed, forType: .string)
        monitor.markInternalWrite()
        lastConversionPreview = String(processed.prefix(50))
        conversionCount += 1
        isProcessing = false
        historyStore.addEntry(text: text, mode: "plainText", detectedType: nil)
    }

    // MARK: - UI Actions

    func toggleHistory() { HistoryWindowController.shared.toggle() }

    // MARK: - 模式切换

    /// 切换工作模式
    func switchMode(to newMode: PasteMode) {
        mode = newMode
        // 模式切换后标记内部写入，避免立即处理上一个模式残留的变化
        monitor.markInternalWrite()
    }

    // MARK: - 购买 / 升级 Pro

    /// 触发 StoreKit 购买
    func purchasePro() {
        Task { await storeManager.purchase() }
    }

    /// 恢复购买
    func restorePurchase() {
        Task { await storeManager.restorePurchases() }
    }

    // MARK: - 开机启动管理

    /// 判断当前运行环境能否操作登录项
    /// SMAppService 要求 App 位于 /Applications 且具有有效签名；
    /// Xcode 调试构建或非 /Applications 路径下必定失败
    private var canManageLoginItem: Bool {
        let path = Bundle.main.bundlePath
        return path.hasPrefix("/Applications/")
            || path.hasPrefix("/System/Applications/")
    }

    /// 更新登录项注册状态
    func updateLoginItem() async {
        // 开发环境下直接跳过，避免无意义的 Operation not permitted 错误
        guard canManageLoginItem else { return }

        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try await SMAppService.mainApp.unregister()
            }
        } catch {
            // 注册失败回退开关状态
            await MainActor.run {
                launchAtLogin = false
                print("ActionSense: 开机启动设置失败 - \(error.localizedDescription)")
            }
        }
    }

    /// 同步当前登录项的实际状态
    private func syncLoginItemState() async {
        // 开发环境下跳过，避免不必要的 SMAppService 调用
        guard canManageLoginItem else { return }

        let status = SMAppService.mainApp.status
        await MainActor.run {
            switch status {
            case .enabled:
                launchAtLogin = true
            default:
                launchAtLogin = false
            }
        }
    }

    // MARK: - 试用提示判断

    /// 是否应该在菜单中显示升级提示
    var shouldShowUpgradePrompt: Bool {
        !storeManager.isPro && storeManager.remainingCount <= 3
    }
}
