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

  @Storage(key: "cachedSales", defaultValue: [])
  private var cachedSales: [SaleDetails]

  @Storage(key: "salesLastFetchedDate", defaultValue: nil)
  private var lastFetchedDate: Double?

  private init() {}

  // MARK: - Public Methods

  func shouldShowSale() async -> SaleDetails? {
    // 1. Use cached sales (populated by foreground task)
    let sales = cachedSales
    guard sales.isNotEmpty else { return nil }

    // 2. Check for override first
    if let overriddenId = UserDefaults.group.string(forKey: String.SaleOverrideKey.overriddenSaleId),
       let overriddenSale = sales.first(where: { $0.id == overriddenId }) {
      return overriddenSale
    }

    // 3. Filter by user type and date range
    guard let applicableSale = await findApplicableSale(from: sales) else {
      return nil
    }

    // 4. Check display frequency using calendar days
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

  /// Refreshes cached sales if needed based on time since last fetch
  /// - Fetches every 3 days normally
  /// - Fetches every 1 day if there's an active sale in the cache
  func refreshSalesIfNeeded() async {
    let now = Date()

    // Determine refresh interval based on whether there's an active sale
    let hasActiveSale = cachedSales.contains { $0.isCurrentlyActive(at: now) }
    let refreshIntervalDays = hasActiveSale ? 1 : 3

    // Check if refresh is needed
    if let lastFetched = lastFetchedDate {
      let lastFetchedDate = Date(timeIntervalSince1970: lastFetched)
      let daysSince = Calendar.current.dateComponents([.day], from: lastFetchedDate, to: now).day ?? 0
      guard daysSince >= refreshIntervalDays else { return }
    }

    // Fetch and cache
    guard let sales = try? await NetworkRequester.shared.getActiveSales().sales else { return }
    cachedSales = sales
    lastFetchedDate = now.timeIntervalSince1970
  }

  /// Force refreshes sales from the backend (for debug view)
  func forceRefreshSales() async {
    guard let sales = try? await NetworkRequester.shared.getActiveSales().sales else { return }
    cachedSales = sales
    lastFetchedDate = Date().timeIntervalSince1970
  }

  /// Returns cached sales (for debug view)
  func getCachedSales() -> [SaleDetails] {
    cachedSales
  }

  /// Returns the last fetched date (for debug view)
  func getLastFetchedDate() -> Date? {
    guard let timestamp = lastFetchedDate else { return nil }
    return Date(timeIntervalSince1970: timestamp)
  }

  /// Computes eligibility state for a single sale (for debug display)
  func getEligibilityState(for sale: SaleDetails) async -> SaleEligibilityState {
    let now = Date()
    let userType = await determineUserType()

    // Calculate days since last shown
    let daysSinceLastShown: Int?
    if let lastShownTimestamp = lastShownSaleDates[sale.id] {
      let lastShownDate = Date(timeIntervalSince1970: lastShownTimestamp)
      let calendar = Calendar.current
      let lastShownDay = calendar.startOfDay(for: lastShownDate)
      let today = calendar.startOfDay(for: now)
      daysSinceLastShown = calendar.dateComponents([.day], from: lastShownDay, to: today).day
    } else {
      daysSinceLastShown = nil
    }

    let displayFrequencyMet = daysSinceLastShown == nil || (daysSinceLastShown ?? 0) >= sale.displayFrequencyDays

    return SaleEligibilityState(
      isActive: sale.isActive,
      isWithinDateRange: now >= sale.startDate && now <= sale.endDate,
      currentDate: now,
      startDate: sale.startDate,
      endDate: sale.endDate,
      userAudienceMatches: sale.targetAudiences.contains(userType),
      userAudienceType: userType,
      targetAudiences: sale.targetAudiences,
      displayFrequencyMet: displayFrequencyMet,
      displayFrequencyDays: sale.displayFrequencyDays,
      daysSinceLastShown: daysSinceLastShown
    )
  }

  // MARK: - Private Methods

  private func determineUserType() async -> TargetAudience {
    let hasBloomPro = await EntitlementController.shared.hasBloomPro
    let entitlement = await EntitlementController.shared.bloomProEntitlement

    if hasBloomPro == true {
      return .subscribedUsers
    } else if let entitlement = entitlement, !entitlement.isActive && entitlement.originalPurchaseDate != nil {
      return .expiredUsers
    } else {
      return .freeUsers
    }
  }

  private func findApplicableSale(from sales: [SaleDetails]) async -> SaleDetails? {
    let userType = await determineUserType()
    let now = Date()

    return sales.first { sale in
      sale.targetAudiences.contains(userType) && sale.isCurrentlyActive(at: now)
    }
  }
}
