//
//  SaleDetails.swift
//  bloom-model
//
//  Created by Claude on 2025-12-02.
//

import Foundation

public struct SaleDetails: Codable, Equatable, Sendable, Identifiable {
  public let id: String
  public let title: String
  public let bodyText: String
  public let imageURL: String?
  public let imageId: String?
  public let saleProductId: String
  public let compareProductId: String?
  public let targetAudiences: [TargetAudience]
  public let startDate: Date
  public let endDate: Date
  public let displayFrequencyDays: Int
  public let isActive: Bool
  public let telemetryEventName: String
  public let purchaseButtonTitle: String?
  public let purchaseButtonGradientColors: [String]?
  public let purchaseButtonFooterText: String?
  public let discountBadgeBackgroundColor: String?
  public let discountBadgeForegroundColor: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: String,
    title: String,
    bodyText: String,
    imageURL: String?,
    imageId: String?,
    saleProductId: String,
    compareProductId: String?,
    targetAudiences: [TargetAudience],
    startDate: Date,
    endDate: Date,
    displayFrequencyDays: Int,
    isActive: Bool,
    telemetryEventName: String,
    purchaseButtonTitle: String?,
    purchaseButtonGradientColors: [String]?,
    purchaseButtonFooterText: String?,
    discountBadgeBackgroundColor: String?,
    discountBadgeForegroundColor: String?,
    createdAt: Date?,
    updatedAt: Date?
  ) {
    self.id = id
    self.title = title
    self.bodyText = bodyText
    self.imageURL = imageURL
    self.imageId = imageId
    self.saleProductId = saleProductId
    self.compareProductId = compareProductId
    self.targetAudiences = targetAudiences
    self.startDate = startDate
    self.endDate = endDate
    self.displayFrequencyDays = displayFrequencyDays
    self.isActive = isActive
    self.telemetryEventName = telemetryEventName
    self.purchaseButtonTitle = purchaseButtonTitle
    self.purchaseButtonGradientColors = purchaseButtonGradientColors
    self.purchaseButtonFooterText = purchaseButtonFooterText
    self.discountBadgeBackgroundColor = discountBadgeBackgroundColor
    self.discountBadgeForegroundColor = discountBadgeForegroundColor
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public enum TargetAudience: String, Codable, Equatable, Sendable, CaseIterable {
  case freeUsers
  case subscribedUsers
  case expiredUsers

  public var displayName: String {
    switch self {
    case .freeUsers: return "Free Users"
    case .subscribedUsers: return "Subscribed Users"
    case .expiredUsers: return "Expired Users"
    }
  }
}
