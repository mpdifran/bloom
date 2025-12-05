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
  @Published var purchaseButtonTitle: String
  @Published var purchaseButtonGradientColors: [String]
  @Published var purchaseButtonFooterText: String
  @Published var discountBadgeBackgroundColor: String
  @Published var discountBadgeForegroundColor: String

  // UI state
  @Published var error: Error?
  @Published var saveButtonText = "Save"
  @Published var selectedImage: NSImage?
  @Published var isImageChanged = false

  private let saleId: String?
  @Published private var imageURL: String?
  private let createdAt: Date?
  private let updatedAt: Date?
  private let store: SalesStore

  // Original values for change detection
  private let originalTitle: String
  private let originalBodyText: String
  private let originalSaleProductId: String
  private let originalCompareProductId: String
  private let originalTargetAudiences: Set<TargetAudience>
  private let originalStartDate: Date
  private let originalEndDate: Date
  private let originalDisplayFrequencyDays: Int
  private let originalIsActive: Bool
  private let originalTelemetryEventName: String
  private let originalPurchaseButtonTitle: String
  private let originalPurchaseButtonGradientColors: [String]
  private let originalPurchaseButtonFooterText: String
  private let originalDiscountBadgeBackgroundColor: String
  private let originalDiscountBadgeForegroundColor: String

  var isNewSale: Bool {
    saleId == nil
  }

  var hasChanges: Bool {
    title != originalTitle ||
    bodyText != originalBodyText ||
    saleProductId != originalSaleProductId ||
    compareProductId != originalCompareProductId ||
    targetAudiences != originalTargetAudiences ||
    startDate != originalStartDate ||
    endDate != originalEndDate ||
    displayFrequencyDays != originalDisplayFrequencyDays ||
    isActive != originalIsActive ||
    telemetryEventName != originalTelemetryEventName ||
    purchaseButtonTitle != originalPurchaseButtonTitle ||
    purchaseButtonGradientColors != originalPurchaseButtonGradientColors ||
    purchaseButtonFooterText != originalPurchaseButtonFooterText ||
    discountBadgeBackgroundColor != originalDiscountBadgeBackgroundColor ||
    discountBadgeForegroundColor != originalDiscountBadgeForegroundColor ||
    isImageChanged
  }

  var canSave: Bool {
    isNewSale || hasChanges
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
    self.purchaseButtonTitle = sale.purchaseButtonTitle ?? ""
    self.purchaseButtonGradientColors = sale.purchaseButtonGradientColors ?? []
    self.purchaseButtonFooterText = sale.purchaseButtonFooterText ?? ""
    self.discountBadgeBackgroundColor = sale.discountBadgeBackgroundColor ?? ""
    self.discountBadgeForegroundColor = sale.discountBadgeForegroundColor ?? ""

    // Store original values for change detection
    self.originalTitle = sale.title
    self.originalBodyText = sale.bodyText
    self.originalSaleProductId = sale.saleProductId
    self.originalCompareProductId = sale.compareProductId ?? ""
    self.originalTargetAudiences = Set(sale.targetAudiences)
    self.originalStartDate = sale.startDate
    self.originalEndDate = sale.endDate
    self.originalDisplayFrequencyDays = sale.displayFrequencyDays
    self.originalIsActive = sale.isActive
    self.originalTelemetryEventName = sale.telemetryEventName
    self.originalPurchaseButtonTitle = sale.purchaseButtonTitle ?? ""
    self.originalPurchaseButtonGradientColors = sale.purchaseButtonGradientColors ?? []
    self.originalPurchaseButtonFooterText = sale.purchaseButtonFooterText ?? ""
    self.originalDiscountBadgeBackgroundColor = sale.discountBadgeBackgroundColor ?? ""
    self.originalDiscountBadgeForegroundColor = sale.discountBadgeForegroundColor ?? ""
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
        purchaseButtonTitle: purchaseButtonTitle.isEmpty ? nil : purchaseButtonTitle,
        purchaseButtonGradientColors: purchaseButtonGradientColors.isEmpty ? nil : purchaseButtonGradientColors,
        purchaseButtonFooterText: purchaseButtonFooterText.isEmpty ? nil : purchaseButtonFooterText,
        discountBadgeBackgroundColor: discountBadgeBackgroundColor.isEmpty ? nil : discountBadgeBackgroundColor,
        discountBadgeForegroundColor: discountBadgeForegroundColor.isEmpty ? nil : discountBadgeForegroundColor,
        createdAt: createdAt,
        updatedAt: updatedAt
      )

      if isNewSale {
        if let updatedSale = try await store.create(sale: sale, image: selectedImage) {
          imageURL = updatedSale.imageURL
        }
      } else {
        if let updatedSale = try await store.update(sale: sale, image: isImageChanged ? selectedImage : nil) {
          imageURL = updatedSale.imageURL
        }
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
        purchaseButtonTitle: purchaseButtonTitle.isEmpty ? nil : purchaseButtonTitle,
        purchaseButtonGradientColors: purchaseButtonGradientColors.isEmpty ? nil : purchaseButtonGradientColors,
        purchaseButtonFooterText: purchaseButtonFooterText.isEmpty ? nil : purchaseButtonFooterText,
        discountBadgeBackgroundColor: discountBadgeBackgroundColor.isEmpty ? nil : discountBadgeBackgroundColor,
        discountBadgeForegroundColor: discountBadgeForegroundColor.isEmpty ? nil : discountBadgeForegroundColor,
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
