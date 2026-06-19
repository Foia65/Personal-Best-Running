import SwiftUI
import StoreKit
import Combine

/// Manages in-app purchases using StoreKit 2 APIs.
/// Handles product fetching, purchase flow, restoration, and transaction verification.
class StoreKitManager: ObservableObject {

    static let shared = StoreKitManager()

    /// Published to trigger UI updates when user's premium status changes.
    @AppStorage("isPremiumUser") var isPremiumUser: Bool = false
    /// Localized price string for the premium product.
    @Published @MainActor var premiumLocalizedPrice: String?
    /// Whether a purchase is currently in progress.
    @Published @MainActor var isPurchasing: Bool = false

    private var products: [StoreKit.Product] = []
    private let premiumProductID = "PB_Running_Premium_ID"
    private var transactionObserver: Task<Void, Never>?

    init() {
        // Start background task to listen for transaction updates
        transactionObserver = observeTransactionUpdates()

        // Fetch products and check existing purchases on launch
        Task {
            await requestProducts()
            await checkCurrentPurchases()
        }
    }

    deinit {
        transactionObserver?.cancel()
    }

    /// Fetches the premium product from App Store and caches the localized price.
    @MainActor
    func requestProducts() async {
        do {
            products = try await StoreKit.Product.products(for: [premiumProductID])
            print("Fetched products: \(products.map { $0.id })")
            if let premium = products.first(where: { $0.id == premiumProductID }) {
                self.premiumLocalizedPrice = premium.displayPrice
            }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    /// Initiates the purchase flow for the premium subscription.
    @MainActor
    func purchasePremium() async {
        guard let premiumProduct = products.first(where: { $0.id == premiumProductID }) else {
            print("\(premiumProductID) Premium product not found.")
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            // StoreKit 2 purchase returns a verification result that must be checked
            let result = try await premiumProduct.purchase()

            switch result {
            case .success(let verificationResult):
                print("Purchase successful. Verifying transaction...")
                await handlePurchaseVerification(verificationResult)
            case .userCancelled:
                print("Purchase cancelled by user.")
            case .pending:
                print("Purchase is pending.")
            @unknown default:
                print("Unknown purchase result.")
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }

    /// Restores previous purchases via App Store sync.
    @MainActor
    func restorePurchases() async {
        print("Attempting to restore purchases...")
        do {
            try await AppStore.sync()
            await checkCurrentPurchases()

            if isPremiumUser {
                print("Purchases restored successfully. User is premium.")
            } else {
                print("No premium purchase found to restore.")
            }

        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    /// Checks current entitlements to determine if user has active premium status.
    @MainActor
    func checkCurrentPurchases() async {
        var foundActivePremium = false

        // Iterate through all current entitlements from StoreKit 2
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == premiumProductID {
                    // Skip revoked transactions
                    guard transaction.revocationDate == nil else {
                        print("Premium transaction found but revoked: \(transaction.id)")
                        await transaction.finish()
                        continue
                    }

                    // Check subscription or non-consumable status
                    if transaction.productType == .autoRenewable {
                        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                            foundActivePremium = true
                            print("Found active premium subscription: \(transaction.id)")
                        } else {
                            print("Premium subscription found but expired: \(transaction.id)")
                        }
                    } else if transaction.productType == .nonConsumable {
                        foundActivePremium = true
                        print("Found active non-consumable premium purchase: \(transaction.id)")
                    }

                    await transaction.finish()
                }
            } catch {
                print("Error checking existing purchase: \(error)")
            }
        }

        isPremiumUser = foundActivePremium
        if foundActivePremium {
            print("Overall: User is a premium user.")
        } else {
            print("Overall: User is NOT a premium user.")
        }
    }

    /// Handles purchase verification and updates user's premium status.
    private func handlePurchaseVerification(_ verificationResult: StoreKit.VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try checkVerified(verificationResult)

            if transaction.productID == premiumProductID && transaction.revocationDate == nil {
                if transaction.productType == .autoRenewable {
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        isPremiumUser = true
                        print("User is now a premium user (subscription active)! Transaction ID: \(transaction.id)")
                    } else {
                        print("Premium subscription found but expired or no expiration date. Transaction ID: \(transaction.id)")
                        isPremiumUser = false
                    }
                } else {
                    isPremiumUser = true
                    print("User is now a premium user (non-consumable)! Transaction ID: \(transaction.id)")
                }
            } else {
                print("Transaction found for premium product but is not valid (revoked or wrong ID). Transaction ID: \(transaction.id)")
                isPremiumUser = false
            }

            await transaction.finish()
        } catch {
            print("Transaction verification failed: \(error)")
            isPremiumUser = false
        }
    }

    /// Verifies the cryptographic signature of a transaction.
    /// Throws if verification fails.
    private func checkVerified(_ result: StoreKit.VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .unverified(let unverifiedTransaction, let error):
            throw StoreError.failedVerification(unverifiedTransaction, error)
        case .verified(let verifiedTransaction):
            return verifiedTransaction
        }
    }

    /// Creates a background task that listens for transaction updates.
    /// Called when App Store transactions are updated (e.g., refunded, expired).
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in StoreKit.Transaction.updates {
                print("Received transaction update...")
                await handlePurchaseVerification(verificationResult)
            }
        }
    }
}

// MARK: - Error Types

enum StoreError: Error, LocalizedError {
    case failedVerification(StoreKit.Transaction, Error)
    case invalidProductID

    var errorDescription: String? {
        switch self {
        case .failedVerification(_, let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .invalidProductID:
            return "Invalid product ID."
        }
    }
}
