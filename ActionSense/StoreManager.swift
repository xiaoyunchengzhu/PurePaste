import StoreKit
import SwiftUI

// MARK: - StoreKit 2 Pro 购买管理

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// Pro 是否已解锁
    @Published var isPro: Bool = false
    /// 正在加载产品信息
    @Published var isLoading: Bool = false
    /// 产品信息
    @Published var proProduct: Product? = nil
    /// 购买错误
    @Published var purchaseError: String? = nil

    /// 每日 PasteFlow 使用次数（Pro 用户不受限）
    @AppStorage("dailyUsageCount") private var dailyUsageCount: Int = 0
    @AppStorage("dailyUsageDate") private var dailyUsageDate: String = ""

    private let productID = "com.actionsense.pro.unlock"
    private let dailyLimit = 20

    private var updateTask: Task<Void, Never>? = nil

    // MARK: - 初始化

    private init() {
        updateTask = Task {
            // 监听交易更新
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == productID {
                        isPro = true
                        await transaction.finish()
                    }
                }
            }
        }

        Task {
            await checkEntitlement()
            await loadProduct()
        }
    }

    // MARK: - 权限检查

    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isPro = true
                return
            }
        }
        isPro = false
    }

    // MARK: - 加载产品

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [productID])
            proProduct = products.first
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - 购买

    func purchase() async {
        #if DEBUG
        // Debug 环境没有 App Store Connect，直接模拟购买
        if proProduct == nil {
            isPro = true
            purchaseError = nil
            return
        }
        #endif

        guard let product = proProduct else {
            purchaseError = String(localized: "pro.error")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isPro = true
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = String(localized: "pro.error")
            @unknown default:
                purchaseError = String(localized: "pro.error")
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlement()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - 每日用量

    /// 今日是否还可以使用 PasteFlow
    var canUsePasteFlow: Bool {
        if isPro { return true }
        resetDailyIfNeeded()
        return dailyUsageCount < dailyLimit
    }

    /// 今日剩余次数
    var remainingCount: Int {
        if isPro { return 999 }
        resetDailyIfNeeded()
        return max(0, dailyLimit - dailyUsageCount)
    }

    /// 增加一次使用
    func recordUsage() {
        resetDailyIfNeeded()
        dailyUsageCount += 1
    }

    private func resetDailyIfNeeded() {
        let today = dateString(Date())
        if dailyUsageDate != today {
            dailyUsageDate = today
            dailyUsageCount = 0
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }
}
