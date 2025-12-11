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
import UIKit
import TelemetryDeck

actor SalesManager {
  static let shared = SalesManager()

  @Storage(key: "lastShownSaleDates", defaultValue: [:])
  private var lastShownSaleDates: [String: Double]

  @CodableStorage(key: "cachedSales", defaultValue: [])
  private var cachedSales: [SaleDetails]

  @Storage(key: "salesLastFetchedDate", defaultValue: nil)
  private var lastFetchedDate: Double?

  private init() {}

  // MARK: - Public Methods

  func shouldShowSale() async -> (SaleDetails, UIImage?)? {
    // 1. Use cached sales (populated by foreground task)
    let sales = cachedSales
    guard sales.isNotEmpty else { return nil }

    // 2. Check for override first
    if let overriddenId = UserDefaults.group.string(forKey: String.SaleOverrideKey.overriddenSaleId),
       let overriddenSale = sales.first(where: { $0.id == overriddenId }) {
      // If "always show on foreground" is enabled, skip frequency check
      let alwaysShow = UserDefaults.group.bool(forKey: String.SaleOverrideKey.alwaysShowOnForeground)
      if alwaysShow {
        let image = await loadImage(for: overriddenSale)
        return (overriddenSale, image)
      }

      // Otherwise, check frequency for the override sale
      let calendar = Calendar.current
      let today = calendar.startOfDay(for: Date())

      if let lastShownTimestamp = lastShownSaleDates[overriddenSale.id] {
        let lastShownDate = Date(timeIntervalSince1970: lastShownTimestamp)
        let lastShownDay = calendar.startOfDay(for: lastShownDate)
        let daysSince = calendar.dateComponents([.day], from: lastShownDay, to: today).day ?? 0

        if daysSince >= overriddenSale.displayFrequencyDays {
          let image = await loadImage(for: overriddenSale)
          return (overriddenSale, image)
        }
      } else {
        // Never shown before
        let image = await loadImage(for: overriddenSale)
        return (overriddenSale, image)
      }

      // Override sale exists but doesn't meet frequency, don't show any sale
      return nil
    }

    // 3. Filter by user type and date range
    let applicableSales = await findApplicableSales(from: sales)
    guard applicableSales.isNotEmpty else { return nil }

    // 4. Find first sale that meets display frequency
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    for sale in applicableSales {
      // Check display frequency
      if let lastShownTimestamp = lastShownSaleDates[sale.id] {
        let lastShownDate = Date(timeIntervalSince1970: lastShownTimestamp)
        let lastShownDay = calendar.startOfDay(for: lastShownDate)
        let daysSince = calendar.dateComponents([.day], from: lastShownDay, to: today).day ?? 0

        guard daysSince >= sale.displayFrequencyDays else {
          continue
        }
      }

      // Check product availability via RevenueCat
      let productAvailable = await MainActor.run {
        EntitlementController.shared.package(for: sale.saleProductId) != nil
      }
      guard productAvailable else {
        continue
      }

      let image = await loadImage(for: sale)
      return (sale, image)
    }

    return nil
  }

  func getApplicableSalesWithImages() async -> [(sale: SaleDetails, image: UIImage?)] {
    let sales = cachedSales
    guard sales.isNotEmpty else { return [] }

    // Check for override first (same logic as shouldShowSale)
    if let overriddenId = UserDefaults.group.string(forKey: String.SaleOverrideKey.overriddenSaleId),
       let overriddenSale = sales.first(where: { $0.id == overriddenId }) {
      let image = await loadImage(for: overriddenSale)
      return [(sale: overriddenSale, image: image)]
    }

    // Normal flow: get applicable sales
    let applicableSales = await findApplicableSales(from: sales)

    return await withTaskGroup(of: (SaleDetails, UIImage?).self) { group in
      for sale in applicableSales {
        group.addTask {
          let image = await self.loadImage(for: sale)
          return (sale, image)
        }
      }

      var results: [(sale: SaleDetails, image: UIImage?)] = []
      for await result in group {
        results.append((sale: result.0, image: result.1))
      }
      return results
    }
  }

  private func loadImage(for sale: SaleDetails) async -> UIImage? {
    guard let imageURLString = sale.imageURL,
          let imageURL = URL(string: imageURLString) else {
      return nil
    }

    guard let (data, _) = try? await URLSession.shared.data(from: imageURL),
          let image = UIImage(data: data) else {
      return nil
    }

    return image
  }

  func markSaleAsShown(_ saleId: String) async {
    lastShownSaleDates[saleId] = Date().timeIntervalSince1970
  }

  func clearLastShownDate(for saleId: String) {
    lastShownSaleDates[saleId] = nil
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

    cache(sales, now: now)
  }

  /// Force refreshes sales from the backend (for debug view)
  func forceRefreshSales() async {
    guard let sales = try? await NetworkRequester.shared.getActiveSales().sales else { return }

    cache(sales, now: .now)
  }

  func cache(_ sales: [SaleDetails], now: Date) {
    let newSales = sales.filter({ !cachedSales.contains($0) })
    cachedSales = sales
    lastFetchedDate = now.timeIntervalSince1970
    for sale in newSales {
      TelemetryDeck.signal("Cached Sale", parameters: ["sale": sale.telemetryEventName])
    }
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

  private func findApplicableSales(from sales: [SaleDetails]) async -> [SaleDetails] {
    let userType = await determineUserType()
    let now = Date()

    return sales.filter { sale in
      sale.targetAudiences.contains(userType) && sale.isCurrentlyActive(at: now)
    }
  }
}
