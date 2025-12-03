//
//  SalesManager.swift
//  Bloom
//
//  Created by Claude on 2025-12-02.
//

import BloomFoundation
import BloomModel
import CoreNetwork
import Foundation

actor SalesManager {
  static let shared = SalesManager()

  @Storage(key: "lastShownSaleDates", defaultValue: [:])
  private var lastShownSaleDates: [String: Double]

  private init() {}

  // MARK: - Public Methods

  func shouldShowSale() async -> SaleDetails? {
    // 1. Fetch active sales from backend
    guard let sales = try? await NetworkRequester.shared.getActiveSales().sales else {
      return nil
    }

    // 2. Filter by user type and date range
    guard let applicableSale = await findApplicableSale(from: sales) else {
      return nil
    }

    // 3. Check display frequency using calendar days
    if let lastShownTimestamp = lastShownSaleDates[applicableSale.id] {
      let lastShownDate = Date(timeIntervalSince1970: lastShownTimestamp)

      let calendar = Calendar.current
      let lastShownDay = calendar.startOfDay(for: lastShownDate)
      let today = calendar.startOfDay(for: Date())
      let daysSince = calendar.dateComponents([.day], from: lastShownDay, to: today).day ?? 0

      guard daysSince >= applicableSale.displayFrequencyDays else {
        return nil
      }
    }

    return applicableSale
  }

  func markSaleAsShown(_ saleId: String) async {
    lastShownSaleDates[saleId] = Date().timeIntervalSince1970
  }

  // MARK: - Private Methods

  private func findApplicableSale(from sales: [SaleDetails]) async -> SaleDetails? {
    // Determine user type
    let hasBloomPro = await EntitlementController.shared.hasBloomPro
    let entitlement = await EntitlementController.shared.bloomProEntitlement

    let userType: TargetAudience
    if hasBloomPro == true {
      userType = .subscribedUsers
    } else if let entitlement = entitlement, !entitlement.isActive && entitlement.originalPurchaseDate != nil {
      userType = .expiredUsers
    } else {
      userType = .freeUsers
    }

    // Filter by target audience and date range
    let now = Date()
    return sales.first { sale in
      sale.targetAudiences.contains(userType) &&
      sale.isActive &&
      now >= sale.startDate &&
      now <= sale.endDate
    }
  }
}
