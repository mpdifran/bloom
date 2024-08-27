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
    @State private var triggerHealthPermissionSheet = false
    @State private var error: Error?

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Water",
            showSaveBar: false
        ) { (hasInserted, handleSave) in
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        Task {
                            guard await logWater(quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 125)) else {
                                return
                            }

                            await MainActor.run {
                                didIncrease.toggle()
                                handleSave()
                            }
                        }
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
                        Task {
                            guard await logWater(quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 250)) else {
                                return
                            }

                            await MainActor.run {
                                didIncrease.toggle()
                                handleSave()
                            }
                        }
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
                        Task {
                            guard await logWater(quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: 500)) else {
                                return
                            }

                            await MainActor.run {
                                didIncrease.toggle()
                                handleSave()
                            }
                        }
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
            .healthDataAccessRequest(
                store: healthManager.healthStore,
                shareTypes: [HKQuantityType(.dietaryWater)],
                readTypes: [HKQuantityType(.dietaryWater)],
                trigger: triggerHealthPermissionSheet
            ) { result in
                switch result {
                case .success:
                    Task {
                        if let selectedQuantity, await logWater(quantity: selectedQuantity) {
                            await MainActor.run {
                                didIncrease.toggle()
                                handleSave()
                            }
                        }
                    }
                case .failure(let error):
                    self.error = error
                }
            }
        }
        .tint(.blue)
        .alert(error: $error)
    }
}

private extension WaterActionCardView {

    func logWater(quantity: HKQuantity) async -> Bool {
        do {
            let authStatus = try await healthManager.checkAccess(writeTypes: [HKQuantityType(.dietaryWater)])

            if authStatus == .shouldRequest {
                selectedQuantity = quantity
                triggerHealthPermissionSheet.toggle()
                return false
            }

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
