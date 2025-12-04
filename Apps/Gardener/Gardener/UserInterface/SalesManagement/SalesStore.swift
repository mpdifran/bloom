//
//  SalesStore.swift
//  Gardener
//
//  Created by Claude on 2025-12-02.
//

import AppKit
import AdminBloomModel
import BloomModel
import Foundation

@MainActor
final class SalesStore: ObservableObject {
  static let shared = SalesStore()

  @Published var sales: [AdminSaleRecord] = []
  @Published var isLoading = false
  @Published var error: Error?

  private let service = NetworkStack.shared

  private init() {}

  func loadSales() async {
    isLoading = true
    error = nil

    do {
      let response = try await service.getAllSales()
      sales = response.sales
    } catch {
      // Ignore cancellation errors - these are expected when tasks are cancelled
      if let urlError = error as? URLError, urlError.code == .cancelled {
        return
      }
      self.error = error
    }

    isLoading = false
  }

  func create(sale: AdminSaleRecord, image: NSImage?) async throws -> AdminSaleRecord? {
    var imageFile: ImageFile?
    if let image, let data = image.pngData() {
      imageFile = ImageFile(data: data, fileExtension: "png")
    }

    let request = AdminCreateSaleRequest(sale: sale, image: imageFile)
    let response = try await service.createSale(request: request)

    sales.append(response.sale)

    return response.sale
  }

  func update(sale: AdminSaleRecord, image: NSImage?) async throws -> AdminSaleRecord? {
    var saleToUpdate = sale

    // If there's a new image, upload it separately and update the sale object
    if let image, let saleId = sale.id, let data = image.pngData() {
      let imageFile = ImageFile(data: data, fileExtension: "png")
      let uploadRequest = AdminUploadSaleImageRequest(saleId: saleId, image: imageFile)
      let uploadResponse = try await service.uploadSaleImage(request: uploadRequest)

      // Update the sale with the new imageURL BEFORE calling updateSale
      saleToUpdate = AdminSaleRecord(
        id: saleToUpdate.id,
        title: saleToUpdate.title,
        bodyText: saleToUpdate.bodyText,
        imageURL: uploadResponse.imageURL,  // Use the uploaded URL
        saleProductId: saleToUpdate.saleProductId,
        compareProductId: saleToUpdate.compareProductId,
        targetAudiences: saleToUpdate.targetAudiences,
        startDate: saleToUpdate.startDate,
        endDate: saleToUpdate.endDate,
        displayFrequencyDays: saleToUpdate.displayFrequencyDays,
        isActive: saleToUpdate.isActive,
        telemetryEventName: saleToUpdate.telemetryEventName,
        purchaseButtonTitle: saleToUpdate.purchaseButtonTitle,
        purchaseButtonGradientColors: saleToUpdate.purchaseButtonGradientColors,
        purchaseButtonFooterText: saleToUpdate.purchaseButtonFooterText,
        discountBadgeBackgroundColor: saleToUpdate.discountBadgeBackgroundColor,
        discountBadgeForegroundColor: saleToUpdate.discountBadgeForegroundColor,
        createdAt: saleToUpdate.createdAt,
        updatedAt: saleToUpdate.updatedAt
      )
    }

    let request = AdminUpdateSaleRequest(sale: saleToUpdate)  // Use updated sale
    let response = try await service.updateSale(request: request)

    if let index = sales.firstIndex(where: { $0.id == sale.id }) {
      sales[index] = response.sale
    }

    return response.sale
  }

  func delete(_ sale: AdminSaleRecord) async throws {
    guard let id = sale.id else { return }
    try await service.deleteSale(id: id)
    sales.removeAll { $0.id == id }
  }
}
