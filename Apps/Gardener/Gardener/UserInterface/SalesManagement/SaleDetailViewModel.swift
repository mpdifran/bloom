//
//  SaleDetailViewModel.swift
//  Gardener
//
//  Created by Claude on 2025-12-02.
//

import AdminBloomModel
import AppKit
import BloomModel
import Foundation

@MainActor
final class SaleDetailViewModel: ObservableObject {
  // Editable properties
  @Published var title: String
  @Published var bodyText: String
  @Published var saleProductId: String
  @Published var compareProductId: String
  @Published var targetAudiences: Set<TargetAudience>
  @Published var startDate: Date
  @Published var endDate: Date
  @Published var displayFrequencyDays: Int
  @Published var isActive: Bool
  @Published var telemetryEventName: String

  // UI state
  @Published var error: Error?
  @Published var saveButtonText = "Save"
  @Published var selectedImage: NSImage?
  @Published var isImageChanged = false

  private let saleId: String?
  private let imageURL: String?
  private let createdAt: Date?
  private let updatedAt: Date?
  private let store: SalesStore

  var isNewSale: Bool {
    saleId == nil
  }

  var canSave: Bool {
    !title.isEmpty &&
    !bodyText.isEmpty &&
    !saleProductId.isEmpty &&
    !telemetryEventName.isEmpty &&
    !targetAudiences.isEmpty &&
    displayFrequencyDays >= 1 &&
    displayFrequencyDays <= 30 &&
    startDate < endDate
  }

  init(sale: AdminSaleRecord, store: SalesStore) {
    self.saleId = sale.id
    self.imageURL = sale.imageURL
    self.createdAt = sale.createdAt
    self.updatedAt = sale.updatedAt
    self.store = store

    // Initialize editable properties
    self.title = sale.title
    self.bodyText = sale.bodyText
    self.saleProductId = sale.saleProductId
    self.compareProductId = sale.compareProductId ?? ""
    self.targetAudiences = Set(sale.targetAudiences)
    self.startDate = sale.startDate
    self.endDate = sale.endDate
    self.displayFrequencyDays = sale.displayFrequencyDays
    self.isActive = sale.isActive
    self.telemetryEventName = sale.telemetryEventName
  }

  func save() async {
    guard canSave else { return }

    saveButtonText = "Saving..."
    error = nil

    do {
      let sale = AdminSaleRecord(
        id: saleId,
        title: title,
        bodyText: bodyText,
        imageURL: selectedImage != nil ? nil : imageURL, // Clear if new image
        saleProductId: saleProductId,
        compareProductId: compareProductId.isEmpty ? nil : compareProductId,
        targetAudiences: Array(targetAudiences),
        startDate: startDate,
        endDate: endDate,
        displayFrequencyDays: displayFrequencyDays,
        isActive: isActive,
        telemetryEventName: telemetryEventName,
        createdAt: createdAt,
        updatedAt: updatedAt
      )

      if isNewSale {
        _ = try await store.create(sale: sale, image: selectedImage)
      } else {
        _ = try await store.update(sale: sale, image: isImageChanged ? selectedImage : nil)
      }

      selectedImage = nil
      isImageChanged = false
      saveButtonText = "Saved!"

      Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        saveButtonText = "Save"
      }
    } catch {
      self.error = error
      saveButtonText = "Save"
    }
  }

  func delete() async {
    guard !isNewSale, let saleId else { return }

    error = nil

    do {
      let sale = AdminSaleRecord(
        id: saleId,
        title: title,
        bodyText: bodyText,
        imageURL: imageURL,
        saleProductId: saleProductId,
        compareProductId: compareProductId.isEmpty ? nil : compareProductId,
        targetAudiences: Array(targetAudiences),
        startDate: startDate,
        endDate: endDate,
        displayFrequencyDays: displayFrequencyDays,
        isActive: isActive,
        telemetryEventName: telemetryEventName,
        createdAt: createdAt,
        updatedAt: updatedAt
      )
      try await store.delete(sale)
    } catch {
      self.error = error
    }
  }

  func selectImage() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.png, .jpeg]

    if panel.runModal() == .OK, let url = panel.url {
      selectedImage = NSImage(contentsOf: url)
      isImageChanged = true
    }
  }

  func clearImage() {
    selectedImage = nil
    isImageChanged = true
  }

  var currentImageURL: String? {
    if selectedImage != nil {
      return nil // Will be uploaded
    }
    return imageURL
  }
}
