//
//  WaterActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SFSafeSymbols
import AppUI
@preconcurrency import HealthKit
import HealthKitUI
import TelemetryDeck
import CoreHealth

struct WaterActionCardView: View {

  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)?) {
    self.performDismiss = performDismiss

    let glassSizes: [WaterGlassSizeModel]
    if
      let data = UserDefaults.group.data(forKey: "WaterActionCardView.glassSizes"),
      let sizes = try? JSONDecoder.main.decode([WaterGlassSizeModel].self, from: data)
    {
      glassSizes = sizes
    } else {
      glassSizes = []
    }

    if glassSizes.isEmpty {
      self.glassSizes = [
        WaterGlassSizeModel(name: "1/2 Cup", quantityValue: 125, unit: .literUnit(with: .milli)),
        WaterGlassSizeModel(name: "1 Cup", quantityValue: 250, unit: .literUnit(with: .milli)),
        WaterGlassSizeModel(name: "2 Cups", quantityValue: 500, unit: .literUnit(with: .milli))
      ]
    } else {
      self.glassSizes = glassSizes
    }
  }

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var didIncrease = false
  @State private var didError = false
  @State private var selectedQuantity: HKQuantity?
  @State private var isShowingAddGlassSizeSheet = false
  @State private var error: Error?

  @Environment(\.requestReview) private var requestReview

  @State private var glassSizes: [WaterGlassSizeModel] {
    didSet {
      if let data = try? JSONEncoder.main.encode(glassSizes) {
        UserDefaults.group.set(data, forKey: "WaterActionCardView.glassSizes")
      }
    }
  }

  var body: some View {
    CardView {
      LargeTitleActionCard("Log Water") {
        HealthActionCardView(
          sampleTypes: [HKQuantityType(.dietaryWater)],
          showSaveBar: false,
          performDismiss: performDismiss
        ) {
            try await logSelectedWater()
          } content: { (hasInserted, handleSave) in
            VStack {
              ForEach(glassSizes) { glassSize in
                WaterGlassSizeCell(model: glassSize)
                  .onTapGesture {
                    selectedQuantity = glassSize.quantity
                    handleSave()
                  }
                  .contextMenu {
                    Button("Delete", systemSymbol: .trash, role: .destructive) {
                      glassSizes.removeAll(where: { $0 == glassSize })
                    }
                  }
                  .sensoryFeedback(.success, trigger: didIncrease)
                  .sensoryFeedback(.error, trigger: didError)
              }
            }
            .overlay {
              ZStack {
                if hasInserted {
                  Label("Water Logged", systemSymbol: .checkmark)
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
              }
              .padding()
            }
          }
      } trailing: {
        Button("Add", systemImage: "plus") {
          isShowingAddGlassSizeSheet = true
        }
      }
    }
    .sheet(isPresented: $isShowingAddGlassSizeSheet) {
      AddWaterGlassSizeView { size in
        glassSizes.append(size)
      }
    }
    .tint(.mutedBlue)
  }
}

private extension WaterActionCardView {

  func logSelectedWater() async throws -> Bool {
    guard let quantity = selectedQuantity else { return false }

    let sample = HKQuantitySample(
      type: HKQuantityType(.dietaryWater),
      quantity: quantity,
      start: Date.now,
      end: Date.now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write(sample)
    didIncrease.toggle()
    TelemetryDeck.signal("Log Water")

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    return true
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      WaterActionCardView(performDismiss: nil)
    }
  }
}
