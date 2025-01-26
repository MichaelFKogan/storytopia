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

    private var productRequest: SKProductsRequest?

    override init() {
        super.init()
        SKPaymentQueue.default().add(self) // Add observer here
    }

    deinit {
        SKPaymentQueue.default().remove(self) // Remove observer to avoid memory leaks
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
        SKPaymentQueue.default().restoreCompletedTransactions() // Restore transactions from App Store
        print("Restore purchases initiated.")
    }


    // Unlock content by marking the product ID as purchased
    private func unlockContent(for productID: String) {
        DispatchQueue.main.async {
            self.purchasedProductIDs.insert(productID)
            self.isSubscribed = true
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




@main
struct StoriesAIApp: App {
    @StateObject private var storeManager = StoreManager()

    init() {
        // Fetch subscription status when the app launches
        storeManager.fetchSubscriptionStatus()
        print("App launched. isSubscribed: \(storeManager.isSubscribed)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .onAppear {
                    // Print subscription status when the main view appears
                    print("isSubscribed (onAppear): \(storeManager.isSubscribed)")
                }
        }
    }
}
