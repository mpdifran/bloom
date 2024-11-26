//
//  BloodPressureActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-27.
//

import SwiftUI
import AppUI
@preconcurrency import HealthKit
import TelemetryDeck

extension BloodPressureActionCardView {
    enum FocusedTextField {
        case systolic
        case diastolic
    }
}

struct BloodPressureActionCardView: View {
    
    @State private var systolic: Double = 120
    @State private var diastolic: Double = 80
    @State private var didError = false
    @State private var error: Error?

    @FocusState private var focusedTextField: FocusedTextField?
    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Blood Pressure",
            sampleTypes: [
                HKQuantityType(.bloodPressureSystolic),
                HKQuantityType(.bloodPressureDiastolic)
            ]
        ) {
            await logBloodPressure()
        } content: { (_, handleSave) in
            VStack(spacing: 20) {
                Spacer()

                HStack {
                    Text("Systolic")
                    Spacer()
                    TextField("", value: $systolic, formatter: NumberFormatter.noDecimalPlaces)
                        .frame(width: 130)
                        .fontDesign(.rounded)
                        .keyboardType(.numberPad)
                        .focused($focusedTextField, equals: .systolic)
                        .selectAllTextOnBeginEditing()
                }

                HStack {
                    Text("Diastolic")
                    Spacer()
                    TextField("", value: $diastolic, formatter: NumberFormatter.noDecimalPlaces)
                        .frame(width: 130)
                        .fontDesign(.rounded)
                        .keyboardType(.numberPad)
                        .focused($focusedTextField, equals: .diastolic)
                        .selectAllTextOnBeginEditing()
                }

                Spacer()
            }
            .sensoryFeedback(.error, trigger: didError)
            .textFieldStyle(.roundedBorder)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.trailing)
            .padding()
        }
        .tint(.mutedPink)
        .alert(error: $error)
    }
}

private extension BloodPressureActionCardView {

    func logBloodPressure() async -> Bool {
        do {
            let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
            let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)

            let systolicSample = HKQuantitySample(
                type: HKQuantityType(.bloodPressureSystolic),
                quantity: systolicQuantity,
                start: .now,
                end: .now,
                metadata: [
                    HKMetadataKeyWasUserEntered : true
                ]
            )
            let diastolicSample = HKQuantitySample(
                type: HKQuantityType(.bloodPressureDiastolic),
                quantity: diastolicQuantity,
                start: .now,
                end: .now,
                metadata: [
                    HKMetadataKeyWasUserEntered : true
                ]
            )

            try await HealthStoreModifier.shared.write(samples: [systolicSample, diastolicSample])
            TelemetryDeck.signal("Log Blood Pressure")
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
                BloodPressureActionCardView()
            }
        }
    }
    return PreviewView()
}
