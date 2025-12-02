//
//  AdminSaleRecord.swift
//  AdminBloomModel
//
//  Created by Claude on 2025-12-02.
//

import Foundation
import BloomModel

public struct AdminSaleRecord: Codable, Equatable, Sendable, Hashable {
  public let id: String?
  public let title: String
  public let bodyText: String
  public let imageURL: String?
  public let saleProductId: String
  public let compareProductId: String?
  public let targetAudiences: [TargetAudience]
  public let startDate: Date
  public let endDate: Date
  public let displayFrequencyDays: Int
  public let isActive: Bool
  public let telemetryEventName: String
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: String?,
    title: String,
    bodyText: String,
    imageURL: String?,
    saleProductId: String,
    compareProductId: String?,
    targetAudiences: [TargetAudience],
    startDate: Date,
    endDate: Date,
    displayFrequencyDays: Int,
    isActive: Bool,
    telemetryEventName: String,
    createdAt: Date?,
    updatedAt: Date?
  ) {
    self.id = id
    self.title = title
    self.bodyText = bodyText
    self.imageURL = imageURL
    self.saleProductId = saleProductId
    self.compareProductId = compareProductId
    self.targetAudiences = targetAudiences
    self.startDate = startDate
    self.endDate = endDate
    self.displayFrequencyDays = displayFrequencyDays
    self.isActive = isActive
    self.telemetryEventName = telemetryEventName
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct AdminSalesListResponse: Codable, Equatable, Sendable {
  public let sales: [AdminSaleRecord]

  public init(sales: [AdminSaleRecord]) {
    self.sales = sales
  }
}

public struct AdminCreateSaleRequest: Codable, Equatable, Sendable {
  public let sale: AdminSaleRecord
  public let image: ImageFile?

  public init(sale: AdminSaleRecord, image: ImageFile?) {
    self.sale = sale
    self.image = image
  }
}

public struct AdminUpdateSaleRequest: Codable, Equatable, Sendable {
  public let sale: AdminSaleRecord

  public init(sale: AdminSaleRecord) {
    self.sale = sale
  }
}

public struct AdminSaleResponse: Codable, Equatable, Sendable {
  public let sale: AdminSaleRecord

  public init(sale: AdminSaleRecord) {
    self.sale = sale
  }
}

public struct AdminUploadSaleImageRequest: Codable, Equatable, Sendable {
  public let saleId: String
  public let image: ImageFile

  public init(saleId: String, image: ImageFile) {
    self.saleId = saleId
    self.image = image
  }
}

public struct AdminUploadSaleImageResponse: Codable, Equatable, Sendable {
  public let imageURL: String

  public init(imageURL: String) {
    self.imageURL = imageURL
  }
}
