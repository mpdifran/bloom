//
//  AdminSalesController.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-12-02.
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import Vapor

struct AdminSalesController { }

extension AdminSalesController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("sales") {
          $0.get(use: getAllSales)
          $0.post("create", use: createSale)
          $0.patch("update", use: updateSale)
          $0.delete(":id", use: deleteSale)
          $0.post(":id", "upload-image", use: uploadImage)
        }
      }
    }
  }
}

private extension AdminSalesController {

  @Sendable
  func getAllSales(_ request: Request) async throws -> AdminSalesListResponse {
    let sales = try await SaleRecord.query(on: request.db)
      .sort(\.$createdAt, .descending)
      .all()

    return AdminSalesListResponse(
      sales: sales.map { $0.asAdminRecord() }
    )
  }

  @Sendable
  func createSale(_ request: Request) async throws -> AdminSaleResponse {
    let requestBody = try request.content.decode(AdminCreateSaleRequest.self)
    let createSale = requestBody.sale

    // Validation
    guard !createSale.title.isEmpty else {
      throw Abort(.badRequest, reason: "Title is required")
    }
    guard !createSale.bodyText.isEmpty else {
      throw Abort(.badRequest, reason: "Body text is required")
    }
    guard !createSale.saleProductId.isEmpty else {
      throw Abort(.badRequest, reason: "Sale product ID is required")
    }
    guard !createSale.telemetryEventName.isEmpty else {
      throw Abort(.badRequest, reason: "Telemetry event name is required")
    }
    guard createSale.displayFrequencyDays >= 1 && createSale.displayFrequencyDays <= 30 else {
      throw Abort(.badRequest, reason: "Display frequency days must be between 1 and 30")
    }
    guard createSale.startDate < createSale.endDate else {
      throw Abort(.badRequest, reason: "Start date must be before end date")
    }

    var imageURL: String? = nil
    if let imageFile = requestBody.image {
      let metadata = try await request.imageStorage.store(
        image: imageFile,
        path: .saleImages
      )
      imageURL = try await request.imageStorage.generateImageURL(
        fileName: metadata.filename,
        path: .saleImages,
        expiration: .hours(365 * 24) // Long expiration for sale images (365 days)
      )?.absoluteString
    }

    let newRecord = SaleRecord(
      id: UUID().uuidString,
      title: createSale.title,
      bodyText: createSale.bodyText,
      imageURL: imageURL ?? createSale.imageURL,
      saleProductId: createSale.saleProductId,
      compareProductId: createSale.compareProductId,
      targetAudiences: createSale.targetAudiences.map { SaleRecord.TargetAudienceEnum.from($0) },
      startDate: createSale.startDate,
      endDate: createSale.endDate,
      displayFrequencyDays: createSale.displayFrequencyDays,
      isActive: createSale.isActive,
      telemetryEventName: createSale.telemetryEventName
    )

    try await newRecord.save(on: request.db)

    return AdminSaleResponse(sale: newRecord.asAdminRecord())
  }

  @Sendable
  func updateSale(_ request: Request) async throws -> AdminSaleResponse {
    let requestBody = try request.content.decode(AdminUpdateSaleRequest.self)
    let updateSale = requestBody.sale

    guard let saleId = updateSale.id else {
      throw Abort(.badRequest, reason: "Sale ID is required for update")
    }

    guard let existingRecord = try await SaleRecord.find(saleId, on: request.db) else {
      throw Abort(.notFound, reason: "Sale not found")
    }

    // Validation
    guard !updateSale.title.isEmpty else {
      throw Abort(.badRequest, reason: "Title is required")
    }
    guard !updateSale.bodyText.isEmpty else {
      throw Abort(.badRequest, reason: "Body text is required")
    }
    guard !updateSale.saleProductId.isEmpty else {
      throw Abort(.badRequest, reason: "Sale product ID is required")
    }
    guard !updateSale.telemetryEventName.isEmpty else {
      throw Abort(.badRequest, reason: "Telemetry event name is required")
    }
    guard updateSale.displayFrequencyDays >= 1 && updateSale.displayFrequencyDays <= 30 else {
      throw Abort(.badRequest, reason: "Display frequency days must be between 1 and 30")
    }
    guard updateSale.startDate < updateSale.endDate else {
      throw Abort(.badRequest, reason: "Start date must be before end date")
    }

    // Update fields
    existingRecord.title = updateSale.title
    existingRecord.bodyText = updateSale.bodyText
    existingRecord.imageURL = updateSale.imageURL
    existingRecord.saleProductId = updateSale.saleProductId
    existingRecord.compareProductId = updateSale.compareProductId
    existingRecord.targetAudiences = updateSale.targetAudiences.map { SaleRecord.TargetAudienceEnum.from($0) }
    existingRecord.startDate = updateSale.startDate
    existingRecord.endDate = updateSale.endDate
    existingRecord.displayFrequencyDays = updateSale.displayFrequencyDays
    existingRecord.isActive = updateSale.isActive
    existingRecord.telemetryEventName = updateSale.telemetryEventName

    try await existingRecord.save(on: request.db)

    return AdminSaleResponse(sale: existingRecord.asAdminRecord())
  }

  @Sendable
  func deleteSale(_ request: Request) async throws -> HTTPStatus {
    guard let saleId = request.parameters.get("id") else {
      throw Abort(.badRequest, reason: "Sale ID is required")
    }

    guard let existingRecord = try await SaleRecord.find(saleId, on: request.db) else {
      throw Abort(.notFound, reason: "Sale not found")
    }

    try await existingRecord.delete(on: request.db)

    return .noContent
  }

  @Sendable
  func uploadImage(_ request: Request) async throws -> AdminUploadSaleImageResponse {
    guard let saleId = request.parameters.get("id") else {
      throw Abort(.badRequest, reason: "Sale ID is required")
    }

    guard let existingRecord = try await SaleRecord.find(saleId, on: request.db) else {
      throw Abort(.notFound, reason: "Sale not found")
    }

    let requestBody = try request.content.decode(AdminUploadSaleImageRequest.self)
    let imageFile = requestBody.image

    let metadata = try await request.imageStorage.store(
      image: imageFile,
      path: .saleImages
    )

    guard let imageURL = try await request.imageStorage.generateImageURL(
      fileName: metadata.filename,
      path: .saleImages,
      expiration: .hours(365 * 24) // Long expiration for sale images (365 days)
    ) else {
      throw Abort(.internalServerError, reason: "Failed to generate image URL")
    }

    // Update the sale record with the new image URL
    existingRecord.imageURL = imageURL.absoluteString
    try await existingRecord.save(on: request.db)

    return AdminUploadSaleImageResponse(imageURL: imageURL.absoluteString)
  }
}

extension SaleRecord {
  func asAdminRecord() -> AdminSaleRecord {
    AdminSaleRecord(
      id: id,
      title: title,
      bodyText: bodyText,
      imageURL: imageURL,
      saleProductId: saleProductId,
      compareProductId: compareProductId,
      targetAudiences: targetAudiences.map { $0.toSharedModel() },
      startDate: startDate,
      endDate: endDate,
      displayFrequencyDays: displayFrequencyDays,
      isActive: isActive,
      telemetryEventName: telemetryEventName,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
