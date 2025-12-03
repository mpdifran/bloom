//
//  SaleDetailView.swift
//  Gardener
//
//  Created by Claude on 2025-12-02.
//

import AdminBloomModel
import AppUI
import BloomModel
import SwiftUI

struct SaleDetailView: View {
  @ObservedObject var viewModel: SaleDetailViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      Form {
        imageSection
        basicInfoSection
        productsSection
        targetingSection
        scheduleSection
        purchaseButtonSection
        discountBadgeColorsSection
        analyticsSection
        statusSection
      }
      .formStyle(.grouped)
    }
    .navigationTitle(viewModel.isNewSale ? "New Sale" : "Edit Sale")
    .shelf {
      shelfContent
    }
    .alert(error: $viewModel.error)
  }

  // MARK: - Sections

  private var imageSection: some View {
    Section("Image") {
      VStack(spacing: 12) {
        if let image = viewModel.selectedImage {
          Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 200)
            .cornerRadius(8)
        } else if let imageURL = viewModel.currentImageURL {
          Text("Current Image URL:")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(imageURL)
            .font(.caption)
            .lineLimit(2)
        } else {
          Text("No image selected")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        HStack {
          Button("Select Image") {
            viewModel.selectImage()
          }

          if viewModel.selectedImage != nil || viewModel.currentImageURL != nil {
            Button("Clear Image") {
              viewModel.clearImage()
            }
            .foregroundStyle(.red)
          }
        }
      }
      .padding(.vertical, 8)
    }
  }

  private var basicInfoSection: some View {
    Section("Basic Information") {
      TextField("Title", text: $viewModel.title)

      Text("Body Text")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextEditor(text: $viewModel.bodyText)
        .frame(height: 100)
    }
  }

  private var productsSection: some View {
    Section("Products") {
      TextField("Sale Product ID (Required)", text: $viewModel.saleProductId)

      TextField("Compare Product ID (Optional)", text: $viewModel.compareProductId)
    }
  }

  private var targetingSection: some View {
    Section("Targeting") {
      Text("Target Audiences (select at least one)")
        .font(.caption)
        .foregroundStyle(.secondary)

      Toggle("Free Users", isOn: Binding(
        get: { viewModel.targetAudiences.contains(.freeUsers) },
        set: { isOn in
          if isOn {
            viewModel.targetAudiences.insert(.freeUsers)
          } else {
            viewModel.targetAudiences.remove(.freeUsers)
          }
        }
      ))

      Toggle("Subscribed Users", isOn: Binding(
        get: { viewModel.targetAudiences.contains(.subscribedUsers) },
        set: { isOn in
          if isOn {
            viewModel.targetAudiences.insert(.subscribedUsers)
          } else {
            viewModel.targetAudiences.remove(.subscribedUsers)
          }
        }
      ))

      Toggle("Expired Users", isOn: Binding(
        get: { viewModel.targetAudiences.contains(.expiredUsers) },
        set: { isOn in
          if isOn {
            viewModel.targetAudiences.insert(.expiredUsers)
          } else {
            viewModel.targetAudiences.remove(.expiredUsers)
          }
        }
      ))
    }
  }

  private var scheduleSection: some View {
    Section("Schedule") {
      DatePicker("Start Date", selection: $viewModel.startDate)

      DatePicker("End Date", selection: $viewModel.endDate)

      Stepper("Display Frequency: \(viewModel.displayFrequencyDays) days",
              value: $viewModel.displayFrequencyDays,
              in: 1...30)

      Text("How often the sale modal will auto-show to users")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var purchaseButtonSection: some View {
    Section("Purchase Button Customization") {
      TextField("Button Title (Optional)", text: $viewModel.purchaseButtonTitle)

      Text("Leave empty to use default button text")
        .font(.caption)
        .foregroundStyle(.secondary)

      TextField("Gradient Colors (Optional)", text: $viewModel.purchaseButtonGradientColors)

      Text("Comma-separated hex colors (e.g., #FF5733, #C70039)")
        .font(.caption)
        .foregroundStyle(.secondary)

      TextField("Footer Text (Optional)", text: $viewModel.purchaseButtonFooterText)

      Text("Leave empty to use default footer text")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var discountBadgeColorsSection: some View {
    Section("Discount Badge Colors") {
      TextField("Background Color (Optional)", text: $viewModel.discountBadgeBackgroundColor)

      Text("Hex color for badge background (e.g., #3798C8)")
        .font(.caption)
        .foregroundStyle(.secondary)

      TextField("Foreground/Text Color (Optional)", text: $viewModel.discountBadgeForegroundColor)

      Text("Hex color for badge text (e.g., #FFFFFF)")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("Leave empty to use defaults (blue background, white text)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var analyticsSection: some View {
    Section("Analytics") {
      TextField("Telemetry Event Name (Required)", text: $viewModel.telemetryEventName)

      Text("TelemetryDeck event name logged when sale appears")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var statusSection: some View {
    Section("Status") {
      Toggle("Active", isOn: $viewModel.isActive)

      Text("Only active sales are shown to users")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Shelf

  private var shelfContent: some View {
    HStack {
      if !viewModel.isNewSale {
        Button("Delete", role: .destructive) {
          Task {
            await viewModel.delete()
            dismiss()
          }
        }
      }

      Spacer()

      Button(viewModel.saveButtonText) {
        Task {
          await viewModel.save()
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(!viewModel.canSave)
    }
  }
}

#Preview {
  let sale = AdminSaleRecord(
    id: nil,
    title: "Summer Sale",
    bodyText: "Get 50% off all premium features this summer!",
    imageURL: nil,
    saleProductId: "bloom_pro_annual",
    compareProductId: "bloom_pro_monthly",
    targetAudiences: [.freeUsers, .expiredUsers],
    startDate: Date(),
    endDate: Date().addingTimeInterval(86400 * 30),
    displayFrequencyDays: 7,
    isActive: true,
    telemetryEventName: "sale_summer_2024_shown",
    purchaseButtonTitle: "Get 50% Off",
    purchaseButtonGradientColors: ["#FF5733", "#C70039"],
    purchaseButtonFooterText: "Limited time offer!",
    discountBadgeBackgroundColor: nil,
    discountBadgeForegroundColor: nil,
    createdAt: Date(),
    updatedAt: Date()
  )

  let viewModel = SaleDetailViewModel(sale: sale, store: .shared)

  return NavigationStack {
    SaleDetailView(viewModel: viewModel)
  }
}
