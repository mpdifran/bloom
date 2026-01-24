//
//  ContainerSelectionView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import AppUI
import BloomUI
@preconcurrency import HealthKit
import TelemetryDeck
import CoreHealth

struct ContainerSelectionView: View {
  let drink: DrinkType
  let selectedDate: Date
  let performDismiss: (() -> Void)?

  @State private var containers: [ContainerSizeModel] = ContainerSizeModel.loadAll()
  @State private var selectedContainer: ContainerSizeModel?
  @State private var presentedSheet: SheetType?

  @Environment(\.requestReview) private var requestReview

  enum SheetType: Identifiable {
    case addContainer
    case manageContainers

    var id: String {
      switch self {
      case .addContainer: "addContainer"
      case .manageContainers: "manageContainers"
      }
    }
  }

  var body: some View {
    NavigationStack {
      HealthActionCardView(
        sampleTypes: [
          HKQuantityType(.dietaryWater),
          HKQuantityType(.dietaryCaffeine),
          HKQuantityType(.dietarySugar),
          HKQuantityType(.numberOfAlcoholicBeverages)
        ],
        showSaveBar: false,
        performDismiss: performDismiss
      ) {
        try await logDrink()
      } content: { hasInserted, handleSave in
        ZStack {
          containerGrid(handleSave: handleSave)

          if hasInserted {
            successOverlay
          }
        }
      }
      .navigationTitle("Choose container")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        ToolbarItem(placement: .primaryAction) {
          Button("Manage Containers", systemSymbol: .ellipsis) {
            presentedSheet = .manageContainers
          }
          .buttonStyle(.plain)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .sheet(item: $presentedSheet) { sheet in
      sheetContent(for: sheet)
    }
  }

  private func containerGrid(handleSave: @escaping () -> Void) -> some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)],
        spacing: 12
      ) {
        ForEach(containers) { container in
          ContainerSizeCell(
            container: container,
            drinkColor: drink.liquidColor
          )
          .onTapGesture {
            selectedContainer = container
            handleSave()
          }
        }

        // Add container button
        addContainerButton
      }
      .padding(.horizontal)
      .padding(.bottom, 100)
    }
    .sensoryFeedback(.selection, trigger: drink.id)
  }

  private var successOverlay: some View {
    Label("Drink Logged", systemSymbol: .checkmark)
      .font(.subheadline)
      .bold()
      .foregroundStyle(.invertedText)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 13)
          .fill(.text)
      }
      .transition(.move(edge: .bottom))
      .zStackAlignment(.bottom)
  }

  private var addContainerButton: some View {
    Button {
      presentedSheet = .addContainer
    } label: {
      VStack(spacing: 8) {
        Image(systemSymbol: .plusCircle)
          .font(.title2)
          .foregroundStyle(.secondary)

        Text("Add")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.vertical, 20)
      .background {
        RoundedRectangle(cornerRadius: 16)
          .fill(.fill)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
          .foregroundStyle(.secondary.opacity(0.5))
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func sheetContent(for sheet: SheetType) -> some View {
    switch sheet {
    case .addContainer:
      AddCustomContainerView { container in
        var updatedContainers = ContainerSizeModel.loadAll()
        updatedContainers.append(container)
        ContainerSizeModel.save(updatedContainers)
        containers = updatedContainers
        presentedSheet = nil
      }

    case .manageContainers:
      ManageContainersView()
        .onDisappear {
          // Refresh containers when returning from manage view
          containers = ContainerSizeModel.loadAll()
        }
    }
  }

  // MARK: - Logging

  @MainActor
  private func logDrink() async throws -> Bool {
    guard let container = selectedContainer else {
      return false
    }

    // Calculate amounts based on container volume
    let amountML = container.volumeML
    let hydratedAmount = amountML * drink.hydrationCoefficient

    // 1. Log water/hydration
    let waterSample = HKQuantitySample(
      type: HKQuantityType(.dietaryWater),
      quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: hydratedAmount),
      start: selectedDate,
      end: selectedDate,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )
    try await HealthStoreModifier.shared.write(waterSample)

    // 2. Log caffeine (for caffeinated drinks)
    if let caffeineMG = drink.caffeineContent(forML: amountML), caffeineMG > 0 {
      let caffeineSample = HKQuantitySample(
        type: HKQuantityType(.dietaryCaffeine),
        quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: caffeineMG),
        start: selectedDate,
        end: selectedDate,
        metadata: [
          HKMetadataKeyWasUserEntered: true
        ]
      )
      try await HealthStoreModifier.shared.write(caffeineSample)
    }

    // 3. Log sugar (for sugary drinks)
    if let sugarG = drink.sugarContent(forML: amountML), sugarG > 0 {
      let sugarSample = HKQuantitySample(
        type: HKQuantityType(.dietarySugar),
        quantity: HKQuantity(unit: .gram(), doubleValue: sugarG),
        start: selectedDate,
        end: selectedDate,
        metadata: [
          HKMetadataKeyWasUserEntered: true
        ]
      )
      try await HealthStoreModifier.shared.write(sugarSample)
    }

    // 4. Log alcoholic beverages (for alcohol category)
    if drink.category == .alcohol {
      let alcoholSample = HKQuantitySample(
        type: HKQuantityType(.numberOfAlcoholicBeverages),
        quantity: HKQuantity(unit: .count(), doubleValue: 1),
        start: selectedDate,
        end: selectedDate,
        metadata: [
          HKMetadataKeyWasUserEntered: true
        ]
      )
      try await HealthStoreModifier.shared.write(alcoholSample)
    }

    // Telemetry
    TelemetryDeck.signal("Log Drink", parameters: [
      "drink_type": drink.name,
      "category": drink.category.rawValue,
      "amount_ml": String(Int(amountML)),
      "hydrated_ml": String(Int(hydratedAmount))
    ])

    // Rating prompt
    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    return true
  }
}

// MARK: - Preview

#Preview {
  ContainerSelectionView(
    drink: DrinkType.defaultDrinks.first!,
    selectedDate: Date(),
    performDismiss: nil
  )
}
