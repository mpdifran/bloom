//
//  WaterActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import AppUI
import HealthKit
import HealthKitUI

struct WaterActionCardView: View {

    @State private var didIncrease = false
    @State private var didError = false
    @State private var selectedQuantity: HKQuantity?
    @State private var error: Error?

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Water",
            sampleTypes: [HKQuantityType(.dietaryWater)],
            showSaveBar: false
        ) { (_) in
            await logSelectedWater()
        } content: { (hasInserted, handleSave) in
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        selectedQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: 125)
                        handleSave()
                    } label: {
                        VStack {
                            Text("1/2 Cup")
                                .font(.title)
                                .fontDesign(.rounded)
                            Text("125 mL")
                        }
                    }
                    .buttonStyle(.tertiary)
                    .sensoryFeedback(.success, trigger: didIncrease)
                    .sensoryFeedback(.error, trigger: didError)

                    Button {
                        selectedQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250)
                        handleSave()
                    } label: {
                        VStack {
                            Text("1 Cup")
                                .font(.title)
                                .fontDesign(.rounded)
                            Text("250 mL")
                        }
                    }
                    .buttonStyle(.tertiary)
                    .sensoryFeedback(.increase, trigger: didIncrease)
                    .sensoryFeedback(.error, trigger: didError)

                    Button {
                        selectedQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: 500)
                        handleSave()
                    } label: {
                        VStack {
                            Text("2 Cup")
                                .font(.title)
                                .fontDesign(.rounded)
                            Text("500 mL")
                        }
                    }
                    .buttonStyle(.tertiary)
                    .sensoryFeedback(.increase, trigger: didIncrease)
                    .sensoryFeedback(.error, trigger: didError)

                    Spacer()
                }

                Spacer()

                Label("Water Logged", systemImage: "checkmark")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.invertedText)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 13)
                            .fill(.text)
                    }
                    .opacity(hasInserted ? 1 : 0)
                    .transition(.move(edge: .bottom))
            }
        }
        .tint(.blue)
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

            try await HealthManager.shared.write(sample: sample)
            didIncrease.toggle()
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
