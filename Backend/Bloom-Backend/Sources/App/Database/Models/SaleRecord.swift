//
//  SaleRecord.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-12-02.
//

import Foundation
import Vapor
import Fluent
import BloomModel

final class SaleRecord: Model, @unchecked Sendable {
  static let schema = "sales"

  @ID(custom: "id", generatedBy: .user)
  var id: String?

  @Field(key: "title")
  var title: String

  @Field(key: "body_text")
  var bodyText: String

  @Field(key: "image_url")
  var imageURL: String?

  @Field(key: "image_id")
  var imageId: String?

  @Field(key: "sale_product_id")
  var saleProductId: String

  @Field(key: "compare_product_id")
  var compareProductId: String?

  @Field(key: "target_audiences")
  var targetAudiences: [TargetAudienceEnum]

  @Field(key: "start_date")
  var startDate: Date

  @Field(key: "end_date")
  var endDate: Date

  @Field(key: "display_frequency_days")
  var displayFrequencyDays: Int

  @Field(key: "is_active")
  var isActive: Bool

  @Field(key: "telemetry_event_name")
  var telemetryEventName: String

  @Field(key: "purchase_button_title")
  var purchaseButtonTitle: String?

  @Field(key: "purchase_button_gradient_colors")
  var purchaseButtonGradientColors: [String]?

  @Field(key: "purchase_button_footer_text")
  var purchaseButtonFooterText: String?

  @Field(key: "discount_badge_background_color")
  var discountBadgeBackgroundColor: String?

  @Field(key: "discount_badge_foreground_color")
  var discountBadgeForegroundColor: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(
    id: String,
    title: String,
    bodyText: String,
    imageURL: String?,
    imageId: String?,
    saleProductId: String,
    compareProductId: String?,
    targetAudiences: [TargetAudienceEnum],
    startDate: Date,
    endDate: Date,
    displayFrequencyDays: Int,
    isActive: Bool,
    telemetryEventName: String,
    purchaseButtonTitle: String?,
    purchaseButtonGradientColors: [String]?,
    purchaseButtonFooterText: String?,
    discountBadgeBackgroundColor: String?,
    discountBadgeForegroundColor: String?
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
  }

  func asDetails() -> SaleDetails {
    SaleDetails(
      id: id ?? "",
      title: title,
      bodyText: bodyText,
      imageURL: imageURL,
      imageId: imageId,
      saleProductId: saleProductId,
      compareProductId: compareProductId,
      targetAudiences: targetAudiences.map { $0.toSharedModel() },
      startDate: startDate,
      endDate: endDate,
      displayFrequencyDays: displayFrequencyDays,
      isActive: isActive,
      telemetryEventName: telemetryEventName,
      purchaseButtonTitle: purchaseButtonTitle,
      purchaseButtonGradientColors: purchaseButtonGradientColors,
      purchaseButtonFooterText: purchaseButtonFooterText,
      discountBadgeBackgroundColor: discountBadgeBackgroundColor,
      discountBadgeForegroundColor: discountBadgeForegroundColor,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

extension SaleRecord {
  enum TargetAudienceEnum: String, Codable, FluentEnum {
    static let schema = "target_audience"

    case freeUsers
    case subscribedUsers
    case expiredUsers

    func toSharedModel() -> BloomModel.TargetAudience {
      switch self {
      case .freeUsers: return .freeUsers
      case .subscribedUsers: return .subscribedUsers
      case .expiredUsers: return .expiredUsers
      }
    }

    static func from(_ sharedModel: BloomModel.TargetAudience) -> TargetAudienceEnum {
      switch sharedModel {
      case .freeUsers: return .freeUsers
      case .subscribedUsers: return .subscribedUsers
      case .expiredUsers: return .expiredUsers
      }
    }
  }
}
