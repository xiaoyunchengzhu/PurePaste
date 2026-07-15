import AppKit

// MARK: - 剪贴板监听器（P3: 从 ViewModel 中独立出来）

@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var internalWriteFlag: Bool = false

    var onClipboardChange: ((_ text: String, _ htmlData: Data?) -> Void)?

    func start() {
        stop()
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        if let t = timer { RunLoop.current.add(t, forMode: .common) }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// 标记内部写入，防止死循环
    func markInternalWrite() {
        internalWriteFlag = true
        lastChangeCount = NSPasteboard.general.changeCount
        internalWriteFlag = false
    }

    private func tick() {
        guard !internalWriteFlag else { return }
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        guard let text = pb.string(forType: .string) else { return }
        let html = pb.data(forType: .html)
        onClipboardChange?(text, html)
    }
}
