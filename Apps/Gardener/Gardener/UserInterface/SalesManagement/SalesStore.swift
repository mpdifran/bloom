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
    // If there's a new image, upload it separately
    if let image, let saleId = sale.id, let data = image.pngData() {
      let imageFile = ImageFile(data: data, fileExtension: "png")
      let uploadRequest = AdminUploadSaleImageRequest(saleId: saleId, image: imageFile)
      _ = try await service.uploadSaleImage(request: uploadRequest)
    }

    let request = AdminUpdateSaleRequest(sale: sale)
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
