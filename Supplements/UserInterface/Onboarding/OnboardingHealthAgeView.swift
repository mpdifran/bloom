//
//  OnboardingHealthAgeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import HealthKitUI

@MainActor
struct OnboardingHealthAgeView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var triggerHealthPermissionSheet = false
    @State private var checkForAgeAndSex = false
    @State private var error: Error?

    var body: some View {
        OnboardingCardTemplateView {
            OnboardingTitleCardView(
                title: "Age & Sex",
                message: "Bloom requires your age and sex in order accurately quantify your health data."
            )
        } bottom: {
            ScrollView {
                VStack {
                    LabeledContent("Birthday") {
                        if checkForAgeAndSex {
                            if let age = healthManager.healthStore.age() {
                                Text("\(age) years old")
                            } else {
                                DatePicker(
                                    "",
                                    selection: $healthManager.birthday,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                            }
                        } else {
                            Text("Unknown")
                        }
                    }
                    .cardContainer(fill: .background)
                    .if(!checkForAgeAndSex) {
                        $0.onTapGesture {
                            triggerHealthPermissionSheet.toggle()
                        }
                    }

                    LabeledContent("Sex") {
                        if checkForAgeAndSex {
                            if let sex = healthManager.healthStore.sex(), sex == .male || sex == .female {
                                Text("\(sex == .male ? "Male" : "Female")")
                            } else {
                                Picker("", selection: $healthManager.isFemale) {
                                    Text("Male")
                                        .tag(false)
                                    Text("Female")
                                        .tag(true)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 150)
                            }
                        } else {
                            Text("Unknown")
                        }
                    }
                    .cardContainer(fill: .background)
                    .if(!checkForAgeAndSex) {
                        $0.onTapGesture {
                            triggerHealthPermissionSheet.toggle()
                        }
                    }
                }
                .padding()
            }
        }
        .alert(error: $error)
        .shelf {
            if checkForAgeAndSex {
                VStack {
                    if healthManager.age() < 1 {
                        Text("You must be at least 1 years old to use Bloom.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProminentButton("Continue") {
                        onContinue()
                    }
                    .disabled(healthManager.age() < 1)
                }
            } else {
                ProminentButton("Connect to Health", systemImage: "heart.fill") {
                    triggerHealthPermissionSheet.toggle()
                }
            }
        }
        .task {
            do {
                let authStatus = try await HealthPermissionChecker.shared.checkAccess(readTypes: HealthPermissionChecker.shared.bodyMeasurementTypes)

                if authStatus == .unnecessary {
                    await MainActor.run {
                        checkForAgeAndSex = true
                    }
                }
            } catch { }
        }
        .healthDataAccessRequest(
            store: HealthPermissionChecker.shared.healthStore,
            readTypes: HealthPermissionChecker.shared.bodyMeasurementTypes,
            trigger: triggerHealthPermissionSheet
        ) { result in
            switch result {
            case .success:
                checkForAgeAndSex = true
            case .failure(let error):
                self.error = error
            }
        }
    }
}

#Preview {
    OnboardingHealthAgeView { }
}
