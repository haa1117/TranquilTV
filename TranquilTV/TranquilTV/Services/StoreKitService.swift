import Foundation
import StoreKit

// StoreKit 2 — product IDs from App Store Connect (`IAPProductCatalog`).
@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    static let subscriptionProductId = IAPProductCatalog.subscriptionProductId
    static let oneTimeProductIds = IAPProductCatalog.oneTimeProductIds

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
            products = try await Product.products(for: IAPProductCatalog.allProductIds)
            let loadedIds = Set(products.map(\.id))
            let missing = IAPProductCatalog.allProductIds.subtracting(loadedIds)
            if !missing.isEmpty {
                print("[StoreKit] Products not returned by App Store: \(missing.sorted())")
            }
        } catch {
            purchaseError = error.localizedDescription
            print("[StoreKit] loadProducts error: \(error)")
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
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] Transaction verification failed: \(error)")
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
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
