//
//  BloodPressureActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-27.
//

import SwiftUI
import AppUI
import HealthKit

struct BloodPressureActionCardView: View {
    
    @State private var systolic: Double = 120
    @State private var diastolic: Double = 80
    @State private var didError = false
    @State private var triggerHealthPermissionSheet = false
    @State private var error: Error?

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(title: "Blood Pressure") { (_) in
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
                }

                HStack {
                    Text("Diastolic")
                    Spacer()
                    TextField("", value: $diastolic, formatter: NumberFormatter.noDecimalPlaces)
                        .frame(width: 130)
                        .fontDesign(.rounded)
                        .keyboardType(.numberPad)
                }

                Spacer()
            }
            .sensoryFeedback(.error, trigger: didError)
            .textFieldStyle(.roundedBorder)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.trailing)
            .padding()
            .healthDataAccessRequest(
                store: healthManager.healthStore,
                shareTypes: [
                    HKQuantityType(.bloodPressureSystolic),
                    HKQuantityType(.bloodPressureDiastolic)
                ],
                readTypes: [
                    HKQuantityType(.bloodPressureSystolic),
                    HKQuantityType(.bloodPressureDiastolic)
                ],
                trigger: triggerHealthPermissionSheet
            ) { result in
                switch result {
                case .success:
                    handleSave()
                case .failure(let error):
                    self.error = error
                }
            }
        }
        .tint(.pink)
        .alert(error: $error)
    }
}

private extension BloodPressureActionCardView {

    func logBloodPressure() async -> Bool {
        do {
            let authStatus = try await healthManager.checkAccess(writeTypes: [
                HKQuantityType(.bloodPressureSystolic),
                HKQuantityType(.bloodPressureDiastolic)
            ])

            if authStatus == .shouldRequest {
                triggerHealthPermissionSheet.toggle()
                return false
            }

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

            try await healthManager.write(samples: [systolicSample, diastolicSample])
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
