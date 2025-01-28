//
//  StoriesAIApp.swift
//  StoriesAI
//
//  Created by Mike Kogan on 10/5/24.
//

import SwiftUI
import StoreKit

class StoreManager: NSObject, ObservableObject {
    @Published var products: [SKProduct] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isSubscribed: Bool = false
    @Published var isRestoring: Bool = false


    private var productRequest: SKProductsRequest?

    override init() {
        super.init()
        self.isSubscribed = false
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self) // Remove observer to avoid memory leaks
    }
    
    // Fetch subscription status and products
      func initializeSubscription() {
          fetchSubscriptionStatus()
          fetchProducts(productIDs: ["storytopia_monthly_subscription"])
      }
    
    func fetchSubscriptionStatus() {
        // Fetch the subscription status from your server or locally.
        restorePurchases()
    }

    // Fetch products from App Store
    func fetchProducts(productIDs: [String]) {
        productRequest?.cancel() // Cancel any ongoing requests
        productRequest = SKProductsRequest(productIdentifiers: Set(productIDs))
        productRequest?.delegate = self
        productRequest?.start()
    }

    // Purchase product
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Restore purchases
    func restorePurchases() {
        isSubscribed = false // Reset subscription status before restoring
        isRestoring = true   // Indicate that the restore process is ongoing
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("Restore purchases initiated.")
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DispatchQueue.main.async {
            self.isRestoring = false
            self.checkSubscriptionExpiry() // Check if subscription is valid
            if self.isSubscribed {
                print("Restore purchases completed successfully.")
            } else {
                print("No active subscription found during restore.")
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.isRestoring = false
            print("Restore purchases failed: \(error.localizedDescription)")
        }
    }



    // Unlock content by marking the product ID as purchased
    private func unlockContent(for productID: String) {
        DispatchQueue.main.async {
            self.purchasedProductIDs.insert(productID)
            self.isSubscribed = true // Set to true for subscribed users
        }
    }
    
    func checkSubscriptionExpiry() {
        // Fetch the latest receipt from the device
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            // Validate the receipt with Apple's servers (server-side recommended)
            // If the subscription is expired, set isSubscribed to false
            DispatchQueue.main.async {
                self.isSubscribed = false
            }
        }
    }
}

extension StoreManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
}

extension StoreManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                let productID = transaction.payment.productIdentifier
                unlockContent(for: productID) // Unlock content for purchased or restored
                SKPaymentQueue.default().finishTransaction(transaction) // Finish the transaction

            case .failed:
                if let error = transaction.error as NSError? {
                    print("Purchase failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}








struct ConstrainedWidthModifier: ViewModifier {
    let maxWidthForPadLandscape: CGFloat
    let maxWidthForPadPortrait: CGFloat
    let maxWidthForiPhoneLandscape: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isPad = UIDevice.current.userInterfaceIdiom == .pad

            ZStack {
                // Black background for the full screen
                Color.black
                    .ignoresSafeArea()

                content
                    .frame(
                        width: {
                            if isPad {
                                return isLandscape
                                    ? min(geometry.size.width, maxWidthForPadLandscape)
                                    : min(geometry.size.width, maxWidthForPadPortrait)
                            } else if isLandscape {
                                return min(geometry.size.width, maxWidthForiPhoneLandscape)
                            } else {
                                return geometry.size.width
                            }
                        }(),
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
        }
    }
}



extension View {
    func constrainedWidth(
        maxWidthForPadLandscape: CGFloat,
        maxWidthForPadPortrait: CGFloat,
        maxWidthForiPhoneLandscape: CGFloat
    ) -> some View {
        self.modifier(
            ConstrainedWidthModifier(
                maxWidthForPadLandscape: maxWidthForPadLandscape,
                maxWidthForPadPortrait: maxWidthForPadPortrait,
                maxWidthForiPhoneLandscape: maxWidthForiPhoneLandscape
            )
        )
    }
}








@main
struct StoriesAIApp: App {
    @StateObject private var storeManager = StoreManager()
    private let maxWidthForPadLandscape: CGFloat = 950 // Maximum width for iPad in landscape
    private let maxWidthForPadPortrait: CGFloat = 800  // Maximum width for iPad in portrait
    private let maxWidthForiPhoneLandscape: CGFloat = 700 // Maximum width for iPhone in landscape

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black // Set the global background color to black
                    .ignoresSafeArea() // Ensure it covers the entire screen
                ContentView()
                    .environmentObject(storeManager)
                    .constrainedWidth(
                        maxWidthForPadLandscape: maxWidthForPadLandscape,
                        maxWidthForPadPortrait: maxWidthForPadPortrait,
                        maxWidthForiPhoneLandscape: maxWidthForiPhoneLandscape
                    )
            }
            .onAppear {
                // Print subscription status when the main view appears
                print("isSubscribed (onAppear): \(storeManager.isSubscribed)")
            }
        }
    }
}

