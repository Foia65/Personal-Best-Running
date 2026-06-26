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
    /// Whether the products fetch from Apple has completed (even if empty).
    @Published @MainActor var productsLoaded: Bool = false
    /// Error message when product fetch returns an empty array.
    @Published @MainActor var productsErrorMessage: String?
    /// Last purchase error message for debug/display purposes.
    @Published @MainActor var lastPurchaseError: String?

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
            #if DEBUG
            print("Fetched products: \(products.map { $0.id })")
            #endif
            if let premium = products.first(where: { $0.id == premiumProductID }) {
                self.premiumLocalizedPrice = premium.displayPrice
                productsErrorMessage = nil
            } else {
                productsErrorMessage = "Prodotti non disponibili al momento."
            }
        } catch {
            #if DEBUG
            print("Failed to fetch products: \(error)")
            #endif
            productsErrorMessage = "Impossibile caricare i prodotti. Riprova più tardi."
        }
        productsLoaded = true
    }

    /// Initiates the purchase flow for the premium subscription.
    @MainActor
    func purchasePremium() async {
        guard let premiumProduct = products.first(where: { $0.id == premiumProductID }) else {
            #if DEBUG
            print("[\(premiumProductID)] Premium product not found. Cached products: \(products.map { $0.id })")
            #endif
            return
        }

        #if DEBUG
        print("[Purchase] Starting purchase for product: \(premiumProduct.id) type: \(premiumProduct.type)")
        #endif
        isPurchasing = true
        defer {
            isPurchasing = false
            #if DEBUG
            print("[Purchase] Purchase flow ended (isPurchasing back to false)")
            #endif
        }

        do {
            let result = try await premiumProduct.purchase()
            #if DEBUG
            print("[Purchase] Got result: \(result)")
            #endif

            switch result {
            case .success(let verificationResult):
                #if DEBUG
                print("[Purchase] Success — about to verify. Payload: \(verificationResult)")
                #endif
                await handlePurchaseVerification(verificationResult)
            case .userCancelled:
                #if DEBUG
                print("[Purchase] User cancelled.")
                #endif
            case .pending:
                #if DEBUG
                print("[Purchase] Pending (ask to buy / strong identity).")
                #endif
            @unknown default:
                #if DEBUG
                print("[Purchase] Unknown result: \(result)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[Purchase] Error: \(error)")
            #endif
        }
    }

    /// Restores previous purchases via App Store sync.
    @MainActor
    func restorePurchases() async {
        #if DEBUG
        print("Attempting to restore purchases...")
        #endif
        do {
            try await AppStore.sync()
            await checkCurrentPurchases()

            if isPremiumUser {
                #if DEBUG
                print("Purchases restored successfully. User is premium.")
                #endif
            } else {
                #if DEBUG
                print("No premium purchase found to restore.")
                #endif
            }

        } catch {
            #if DEBUG
            print("Failed to restore purchases: \(error)")
            #endif
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
                        #if DEBUG
                        print("Premium transaction found but revoked: \(transaction.id)")
                        #endif
                        await transaction.finish()
                        continue
                    }

                    // Check subscription or non-consumable status
                    if transaction.productType == .autoRenewable {
                        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                            foundActivePremium = true
                            #if DEBUG
                            print("Found active premium subscription: \(transaction.id)")
                            #endif
                        } else {
                            #if DEBUG
                            print("Premium subscription found but expired: \(transaction.id)")
                            #endif
                        }
                    } else if transaction.productType == .nonConsumable {
                        foundActivePremium = true
                        #if DEBUG
                        print("Found active non-consumable premium purchase: \(transaction.id)")
                        #endif
                    }

                    await transaction.finish()
                }
            } catch {
                #if DEBUG
                print("Error checking existing purchase: \(error)")
                #endif
            }
        }

        isPremiumUser = foundActivePremium
        #if DEBUG
        if foundActivePremium {
            print("Overall: User is a premium user.")
        } else {
            print("Overall: User is NOT a premium user.")
        }
        #endif
    }

    /// Handles purchase verification and updates user's premium status.
    private func handlePurchaseVerification(_ verificationResult: StoreKit.VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try checkVerified(verificationResult)

            if transaction.productID == premiumProductID && transaction.revocationDate == nil {
                if transaction.productType == .autoRenewable {
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        isPremiumUser = true
                        #if DEBUG
                        print("User is now a premium user (subscription active)! Transaction ID: \(transaction.id)")
                        #endif
                    } else {
                        #if DEBUG
                        print("Premium subscription found but expired or no expiration date. Transaction ID: \(transaction.id)")
                        #endif
                        isPremiumUser = false
                    }
                } else {
                    isPremiumUser = true
                    #if DEBUG
                    print("User is now a premium user (non-consumable)! Transaction ID: \(transaction.id)")
                    #endif
                }
            } else {
                #if DEBUG
                print("Transaction found for premium product but is not valid (revoked or wrong ID). Transaction ID: \(transaction.id)")
                #endif
                isPremiumUser = false
            }

            await transaction.finish()
        } catch {
            #if DEBUG
            print("Transaction verification failed: \(error)")
            #endif
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
                #if DEBUG
                print("Received transaction update...")
                #endif
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
