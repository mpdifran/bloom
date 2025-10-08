//
//  PackageStore.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-16.
//

import Foundation
import StoreKit
import TelemetryDeck

enum StoreError: Error {
  case failedVerification
  case purchasePending
}

typealias SubscriptionStatus = StoreKit.Product.SubscriptionInfo.Status
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo

@MainActor
final class PackageStore: NSObject, ObservableObject {
  static let shared = PackageStore()

  @Published private(set) var bloomProStatus: SubscriptionStatus?
  @Published private(set) var activeSubscriptions = [Product]()
  @Published private(set) var subscriptions = [Product]()
  @Published private(set) var transactions = [Transaction]()

  @Published var error: Error?

  private var updateListenerTask: Task<Void, Error>? = nil
  private var purchaseIntentListenerTask: Task<Void, Error>? = nil

  private override init() {
    super.init()

    updateListenerTask = listenForTransactions()

#if os(macOS)
    SKPaymentQueue.default().add(self)
#else
    purchaseIntentListenerTask = listenForPurchaseIntents()
#endif

    Task {
      await requestProducts()
      await updatePurchasedProductStatus()
    }

    fatalError("We should not be using this class at all! We are using RevenueCat.")
  }
}

extension PackageStore {

  var hasBloomPro: Bool {
    bloomProStatus?.state == .inGracePeriod ||
    bloomProStatus?.state == .subscribed
  }

  var purchasedBloomProProduct: Product? {
    if let product = activeSubscriptions.first(where: {
      $0.id == .ProductIdentifier.monthly || $0.id == .ProductIdentifier.yearly
    }) {
      return product
    }
    return nil
  }

  var activeSubscriptionName: String {
    guard let product = purchasedBloomProProduct else { return "Subscription" }
    
    switch product.id {
    case .ProductIdentifier.monthly:
      return "Monthly"
    case .ProductIdentifier.yearly:
      return "Yearly"
    default:
      return "Subscription"
    }
  }

  var statusCellInfo: EntitlementStatusCellInfo? {
    guard 
      let status = bloomProStatus,
      case .verified(let transaction) = status.transaction,
      let expirationDate = transaction.expirationDate
    else { return nil }

    let willRenew: Bool
    switch status.renewalInfo {
    case .verified(let info):
      willRenew = info.willAutoRenew
    case .unverified:
      willRenew = false
    }

    if !willRenew {
      if status.state == .subscribed || status.state == .inGracePeriod, expirationDate > .now {
        return EntitlementStatusCellInfo(
          title: "Expires",
          date: expirationDate
        )
      } else {
        return EntitlementStatusCellInfo(
          title: "Expired",
          date: expirationDate
        )
      }
    } else {
      switch status.state {
      case .subscribed:
        return EntitlementStatusCellInfo(
          title: "Next Charge Date",
          date: expirationDate
        )
      case .inGracePeriod:
        return EntitlementStatusCellInfo(
          title: "Grace Period Ends",
          date: expirationDate
        )
      case .inBillingRetryPeriod:
        return EntitlementStatusCellInfo(
          title: "Billing Retry Ends",
          date: expirationDate
        )
      default:
        return EntitlementStatusCellInfo(
          title: "Subscription Ends",
          date: expirationDate
        )
      }
    }
  }

  func restore() async throws {
    try await AppStore.sync()
    await updatePurchasedProductStatus()
  }

  func purchase(_ product: Product) async throws -> Transaction? {
    let result = try await product.purchase()

    switch result {
    case .success(let verification):
      let transaction = try checkVerified(verification)

      await updatePurchasedProductStatus()
      await transaction.finish()

      TelemetryDeck.purchaseCompleted(transaction: transaction)
      TelemetryDeck.signal(
        "Purchased Product",
        parameters: [
          "productName": product.displayName,
          "productID": product.id
        ]
      )

      return transaction
    case .userCancelled:
      TelemetryDeck.signal(
        "User Cancelled Product Purchase",
        parameters: [
          "productName": product.displayName,
          "productID": product.id
        ]
      )
      return nil
    case .pending:
      throw StoreError.purchasePending
    default:
      return nil
    }
  }

  @MainActor
  func updatePurchasedProductStatus() async {
    var activeSubscriptions = [Product]()
    var transactions = [Transaction]()

    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try checkVerified(result)
        transactions.append(transaction)

        switch transaction.productType {
        case .autoRenewable:
          if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
            activeSubscriptions.append(subscription)
          }
        default:
          break
        }
      } catch {
        print(error)
      }
    }

    self.activeSubscriptions = activeSubscriptions
    self.transactions = transactions

    // Calculate the subscription status using the example here
    // https://furbo.org/2024/03/29/app-store-subscriptions-and-family-sharing
    if let statuses = try? await subscriptions.first?.subscription?.status {
      if let validStatus = statuses.first(where: { $0.state == .subscribed || $0.state == .inGracePeriod }) {
        self.bloomProStatus = validStatus
      } else {
        self.bloomProStatus = try? statuses.sorted(by: {
          let lhsTransaction = try checkVerified($0.transaction)
          let rhsTransaction = try checkVerified($1.transaction)

          return lhsTransaction.purchaseDate > rhsTransaction.purchaseDate
        }).first
      }
    }
  }
}

private extension PackageStore {

  func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      for await result in Transaction.updates {
        do {
          let transaction = try await self.checkVerified(result)

          await self.updatePurchasedProductStatus()

          if let revocationDate = transaction.revocationDate,
             let revocationReason = transaction.revocationReason {
            TelemetryDeck.signal(
              "Transaction Revoked",
              parameters: [
                "revocationDate": "\(revocationDate)",
                "revocationReason": revocationReason.localizedDescription,
                "productID": transaction.productID
              ]
            )
          }

          await transaction.finish()
        } catch {
          //StoreKit has a transaction that fails verification. Don't deliver content to the user.
          print("Transaction failed verification")
        }
      }
    }
  }

  @MainActor
  func requestProducts() async {
    let identifiers = [String.ProductIdentifier.monthlyHalf, String.ProductIdentifier.yearlyHalf]
    var subscriptions = [Product]()

    do {
      let storeProducts = try await Product.products(for: identifiers)

      for product in storeProducts {
        switch product.type {
        case .autoRenewable:
          subscriptions.append(product)
        default:
          print("Unknown product")
        }
      }
    } catch {
      print("Failed product request from the App Store server: \(error)")
      TelemetryDeck.errorOccurred(
        id: "PackageStore.requestProducts",
        category: .thrownException,
        message: error.localizedDescription
      )
    }

    self.subscriptions = subscriptions.sorted(by: { lhs, rhs in
      lhs.price < rhs.price
    })
  }

#if !os(macOS)
  func listenForPurchaseIntents() -> Task<Void, Error> {
    Task.detached {
      for await purchaseIntent in PurchaseIntent.intents {
        do {
          _ = try await purchaseIntent.product.purchase()
        } catch {
          TelemetryDeck.errorOccurred(
            id: "PackageStore.listenForPurchaseIntents",
            category: .thrownException,
            message: error.localizedDescription
          )
          await MainActor.run {
            self.error = error
          }
        }
      }
    }
  }
#endif
}

private extension PackageStore {

  func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }
}

extension PackageStore {

  var bloomProStatusDescription: String {
    if let subscriptionStatus {
      subscriptionStatus
    } else {
      "Your subscription status could not be verified."
    }
  }

  fileprivate var subscriptionStatus: String? {
    guard let status = bloomProStatus,
          case .verified(let renewalInfo) = bloomProStatus?.renewalInfo,
          case .verified(let transaction) = bloomProStatus?.transaction,
          let product = subscriptions.first(where: { $0.id == transaction.productID })
    else {
      return nil
    }

    var description = ""

    switch status.state {
    case .subscribed:
      description = subscribedDescription(product: product)
    case .expired:
      if let expirationDate = transaction.expirationDate,
         let expirationReason = renewalInfo.expirationReason {
        description = expirationDescription(
          product: product,
          expirationReason: expirationReason,
          expirationDate: expirationDate
        )
      }
    case .revoked:
      if let revokedDate = transaction.revocationDate {
        description = "Your subscription to \(product.displayName) was refunded on \(DateFormatter.justDateMedium.string(from: revokedDate))."
      }
    case .inGracePeriod:
      description = gracePeriodDescription(product: product, renewalInfo: renewalInfo)
    case .inBillingRetryPeriod:
      description = billingRetryDescription(product: product)
    default:
      break
    }

    if let expirationDate = transaction.expirationDate {
      description += renewalDescription(
        product: product,
        renewalInfo: renewalInfo,
        expirationDate: expirationDate
      )
    }

    return description
  }

  fileprivate func billingRetryDescription(product: Product) -> String {
    "Your billing information could not be confirmed. Please verify your billing information to resume service."
  }

  fileprivate func gracePeriodDescription(product: Product, renewalInfo: RenewalInfo) -> String {
    var description = "Your billing information could not be confirmed."
    if let untilDate = renewalInfo.gracePeriodExpirationDate {
      description += " Please verify your billing information to continue service after \(DateFormatter.justDateMedium.string(from: untilDate))"
    }

    return description
  }

  fileprivate func subscribedDescription(product: Product) -> String {
    return "You are currently subscribed to \(product.displayName)."
  }

  fileprivate func renewalDescription(product: Product, renewalInfo: RenewalInfo, expirationDate: Date) -> String {
    var description = ""

    if let newProductID = renewalInfo.autoRenewPreference, newProductID != product.id {
      if let newProduct = subscriptions.first(where: { $0.id == newProductID }) {
        description += "\nYour subscription to \(newProduct.displayName)"
        description += " will begin when your current subscription expires on \(DateFormatter.justDateMedium.string(from: expirationDate))."
      }
    } else if renewalInfo.willAutoRenew {
      description += "\nNext billing date: \(DateFormatter.justDateMedium.string(from: expirationDate))."
    }

    return description
  }

  fileprivate func expirationDescription(product: Product, expirationReason: RenewalInfo.ExpirationReason, expirationDate: Date) -> String {
    var description = ""

    switch expirationReason {
    case .autoRenewDisabled:
      if expirationDate > Date() {
        description += "Your subscription to \(product.displayName) will expire on \(DateFormatter.justDateMedium.string(from: expirationDate))."
      } else {
        description += "Your subscription to \(product.displayName) expired on \(DateFormatter.justDateMedium.string(from: expirationDate))."
      }
    case .billingError:
      description = "Your subscription to \(product.displayName) was not renewed due to a billing error."
    case .didNotConsentToPriceIncrease:
      description = "Your subscription to \(product.displayName) was not renewed due to a price increase that you disapproved."
    case .productUnavailable:
      description = "Your subscription to \(product.displayName) was not renewed because the product is no longer available."
    default:
      description = "Your subscription to \(product.displayName) was not renewed."
    }

    return description
  }
}
