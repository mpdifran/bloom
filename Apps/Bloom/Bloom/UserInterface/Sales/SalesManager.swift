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

  private var cacheDirectory: URL {
    let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return cachesDirectory.appendingPathComponent("SaleImages", isDirectory: true)
  }

  // MARK: - Public Methods

  func shouldShowSale() async -> SaleDetails? {
    // 1. Fetch active sales from backend
    guard let sales = try? await NetworkRequester.shared.getActiveSales().sales else {
      return nil
    }

    // 2. Download missing images and clean up orphaned ones
    await downloadMissingImages(for: sales)
    await cleanupOrphanedImages(activeSales: sales)

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

  func getCachedImagePath(imageId: String) -> URL? {
    let imagePath = cacheDirectory.appendingPathComponent("\(imageId).jpg")
    if FileManager.default.fileExists(atPath: imagePath.path) {
      return imagePath
    }
    return nil
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

  private func downloadMissingImages(for sales: [SaleDetails]) async {
    // Create cache directory if it doesn't exist
    try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

    for sale in sales {
      guard let imageId = sale.imageId,
            let imageURL = sale.imageURL,
            let url = URL(string: imageURL) else {
        continue
      }

      // Check if image already exists
      let imagePath = cacheDirectory.appendingPathComponent("\(imageId).jpg")
      if FileManager.default.fileExists(atPath: imagePath.path) {
        continue
      }

      // Download image
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: imagePath)
      } catch {
        // Silently fail - sale can still show without image
        continue
      }
    }
  }

  private func cleanupOrphanedImages(activeSales: [SaleDetails]) async {
    // Get all active imageIds
    let activeImageIds = Set(activeSales.compactMap { $0.imageId })

    // Get all cached files
    guard let cachedFiles = try? FileManager.default.contentsOfDirectory(
      at: cacheDirectory,
      includingPropertiesForKeys: nil
    ) else {
      return
    }

    // Delete any cached files that don't match active imageIds
    for file in cachedFiles {
      let filename = file.deletingPathExtension().lastPathComponent
      if !activeImageIds.contains(filename) {
        try? FileManager.default.removeItem(at: file)
      }
    }
  }
}
