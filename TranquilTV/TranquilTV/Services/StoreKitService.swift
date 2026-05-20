import Foundation
import StoreKit

// TODO: Replace product IDs below with your actual App Store Connect product IDs
@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // TODO: Set these product IDs in App Store Connect
    static let subscriptionProductId = "tranquil_premium_monthly"
    static let oneTimeProductIds: Set<String> = [
        "scene_first_snow",
        "audio_wind_chimes",
        "distant_thunder",
        "crackling_campfire",
        "focus_flow",
        "grounding_stability",
        "anxiety_relief",
        "japanese_forrest",
        "mountains_calm",
    ]

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseError: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var ids = Self.oneTimeProductIds
            ids.insert(Self.subscriptionProductId)
            products = try await Product.products(for: ids)
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            SettingsService.shared.setPurchased(transaction.productID)
            await transaction.finish()
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    func product(id: String) -> Product? { products.first { $0.id == id } }

    func subscriptionProduct() -> Product? { product(id: Self.subscriptionProductId) }

    enum StoreError: Error {
        case failedVerification
    }
}
