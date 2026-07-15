import SwiftUI
import AppKit

// MARK: - AppDelegate，在正确的生命周期节点做初始化

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 确保不显示 Dock 图标（双重保险，配合 Info.plist 中的 LSUIElement）
        NSApp.setActivationPolicy(.accessory)

        // 明显的启动标记，方便在控制台噪音中找到
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        // 注册所有 PasteFlow 内容检测器（优先级链）
        let registry = DetectorRegistry.shared
        registry.register(ColorDetector())        // 0
                registry.register(EmailDetector())        // 2
        registry.register(URLDetector())          // 3
        registry.register(ImageURLDetector())     // 4
        registry.register(PhoneDetector())        // 5
        registry.register(JSONDetector())         // 6
                registry.register(MathDetector())         // 9
        registry.register(GeoDetector())          // 10
        registry.register(DatetimeDetector())     // 11
                registry.register(RichHTMLDetector())     // 13
        registry.lock()

        print("  ✅ ActionSense 已启动")
        print("  📋 查看屏幕右上角菜单栏的剪贴板图标")
        print("  \(L10n.startupMessage)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}

// MARK: - ActionSense 应用入口
// 使用 MenuBarExtra 构建原生菜单栏应用，无 Dock 图标，无主窗口

@main
struct ActionSenseApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 全局 ViewModel，管理剪贴板监听和状态
    @StateObject private var viewModel = ActionSenseViewModel()

    var body: some Scene {
        MenuBarExtra {
            // 弹出菜单内容
            MenuView()
                .environmentObject(viewModel)
        } label: {
            // 菜单栏图标：根据当前模式显示不同图标和颜色
            Image(systemName: viewModel.mode.menuBarIcon)
                .foregroundColor(menuBarTint)
        }
    }

    /// 菜单栏图标颜色：根据模式 + 是否有待处理内容动态变化
    private var menuBarTint: Color {
        switch viewModel.mode {
        case .disabled:
            return .gray
        case .plainText:
            return .blue
        case .pasteFlow:
            return .teal
        }
    }
}
