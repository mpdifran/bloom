//
//  WaterActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import AppUI
@preconcurrency import HealthKit
import HealthKitUI
import TelemetryDeck

struct WaterActionCardView: View {

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var didIncrease = false
    @State private var didError = false
    @State private var selectedQuantity: HKQuantity?
    @State private var isShowingAddGlassSizeSheet = false
    @State private var error: Error?

    @State private var glassSizes: [WaterGlassSizeModel] {
        didSet {
            if let data = try? JSONEncoder.main.encode(glassSizes) {
                UserDefaults.group.set(data, forKey: "WaterActionCardView.glassSizes")
            }
        }
    }

    init() {
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

    var body: some View {
        ActionCardView(
            title: "Log Water",
            sampleTypes: [HKQuantityType(.dietaryWater)],
            showSaveBar: false
        ) {
            await logSelectedWater()
        } content: { (hasInserted, handleSave) in
            List {
                ForEach(glassSizes) { glassSize in
                    HStack {
                        Image(systemName: "waterbottle")
                            .foregroundStyle(.tint)

                        Text(glassSize.name)
                            .fontDesign(.rounded)
                            .bold()

                        Spacer()

                        Text(glassSize.displayValue)
                            .bold()
                            .fontDesign(.rounded)
                            .foregroundStyle(.tint)
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedQuantity = glassSize.quantity
                        handleSave()
                    }
                    .sensoryFeedback(.success, trigger: didIncrease)
                    .sensoryFeedback(.error, trigger: didError)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        glassSizes.remove(at: index)
                    }
                }
            }
            .overlay {
                ZStack {
                    if hasInserted {
                        Label("Water Logged", systemImage: "checkmark")
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddGlassSizeSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tint(.mutedBlue)
        .sheet(isPresented: $isShowingAddGlassSizeSheet) {
            AddWaterGlassSizeView { size in
                glassSizes.append(size)
            }
        }
        .alert(error: $error)
    }
}

private extension WaterActionCardView {

    func logSelectedWater() async -> Bool {
        guard let quantity = selectedQuantity else { return false }

        do {
            let sample = HKQuantitySample(
                type: .init(.dietaryWater),
                quantity: quantity,
                start: .now,
                end: .now,
                metadata: [
                    HKMetadataKeyWasUserEntered : true
                ]
            )

            try await HealthStoreModifier.shared.write(sample: sample)
            didIncrease.toggle()
            TelemetryDeck.signal("Log Water")
            return true
        } catch {
            self.error = error
            self.didError.toggle()
            return false
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                WaterActionCardView()
            }
        }
    }
    return PreviewView()
}
