//
//  BodyWeightActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import SwiftUI
import HealthKit

struct BodyWeightActionCardView: View {

    @State private var weight: Double = 0

    @State private var didError = false
    @State private var error: Error?

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Body Weight",
            sampleTypes: [HKQuantityType(.bodyMass)]
        ) { (_) in
            await logWeight()
        } content: { (_, handleSave) in
            VStack {
                Spacer()

                HStack {
                    TextField("", value: $weight, formatter: NumberFormatter.oneDecimalPlace)
                    Text("lbs")
                }
                .frame(width: 200)
                .fontDesign(.rounded)
                .keyboardType(.decimalPad)
                .sensoryFeedback(.error, trigger: didError)
                .textFieldStyle(.roundedBorder)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.trailing)

                Spacer()
            }
        }
        .alert(error: $error)
        .tint(.indigo)
    }
}

private extension BodyWeightActionCardView {

    func logWeight() async -> Bool {
        do {
            let date = Date.now
            let sample = HKQuantitySample(
                type: .init(.bodyMass),
                quantity: .init(unit: .pound(), doubleValue: weight),
                start: date,
                end: date,
                metadata: [
                    HKMetadataKeyWasUserEntered : true
                ]
            )

            try await HealthManager.shared.write(sample: sample)
        } catch {
            self.error = error
            self.didError.toggle()
            return false
        }

        return true
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
                BodyWeightActionCardView()
            }
        }
    }
    return PreviewView()
}
