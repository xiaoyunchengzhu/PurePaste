import Foundation

// MARK: - Detector 协议（P0: 替换 enum + switch 检测链）

/// 每个内容类型实现此协议，负责判断剪贴板文本是否属于该类型
protocol ContentDetecting: AnyObject, Sendable {
    /// 唯一标识（用于 L10n 查找和注册）
    var identifier: String { get }
    /// 优先级：越小越先检测
    var priority: Int { get }
    /// 是否需要剪贴板 HTML 数据
    var requiresHTMLData: Bool { get }
    /// 尝试检测，返回匹配结果或 nil
    func detect(_ text: String, htmlData: Data?) -> DetectedContent?
}

extension ContentDetecting {
    var requiresHTMLData: Bool { false }
    func detect(_ text: String) -> DetectedContent? {
        detect(text, htmlData: nil)
    }
}

// MARK: - Detector Registry（优先级链管理）

@MainActor
final class DetectorRegistry: @unchecked Sendable {
    static let shared = DetectorRegistry()

    private var detectors: [any ContentDetecting] = []
    private var locked = false

    /// 注册 detector（按 priority 排序）
    func register(_ detector: any ContentDetecting) {
        guard !locked else { return }
        detectors.append(detector)
        detectors.sort { $0.priority < $1.priority }
    }

    /// 锁定注册表（启动后不再接受注册）
    func lock() { locked = true }

    /// 遍历检测链，返回第一个匹配结果
    func detect(_ text: String, htmlData: Data?) -> DetectedContent? {
        for d in detectors {
            if let result = d.detect(text, htmlData: d.requiresHTMLData ? htmlData : nil) {
                return result
            }
        }
        return nil
    }

    /// 所有已注册的 detector 的 identifier 列表
    var registeredIdentifiers: [String] {
        detectors.map { $0.identifier }
    }
}
