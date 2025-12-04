//
//  AdminSaleRecord+PreviewData.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-12-04.
//

import Foundation
import AdminBloomModel

extension AdminSaleRecord {

  static let defaultSale = AdminSaleRecord(
    id: "preview_sale_1",
    title: "New Year Sale",
    bodyText: "Start the year right with 50% off Bloom Pro! Lock in this rate forever.",
    imageURL: nil,
    saleProductId: "bloom_pro_yearly",
    compareProductId: "bloom_pro_monthly",
    targetAudiences: [.freeUsers, .expiredUsers],
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400 * 7), // 7 days from now
    displayFrequencyDays: 3,
    isActive: true,
    telemetryEventName: "sale_new_year_2025_shown",
    purchaseButtonTitle: "Get 50% Off",
    purchaseButtonGradientColors: ["#FF6B6B", "#4ECDC4", "#45B7D1"],
    purchaseButtonFooterText: "Share with up to 5 family members",
    discountBadgeBackgroundColor: "#FF6B6B",
    discountBadgeForegroundColor: "#FFFFFF",
    createdAt: Date(),
    updatedAt: Date()
  )
}
