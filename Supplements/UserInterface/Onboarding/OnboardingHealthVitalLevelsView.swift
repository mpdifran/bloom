//
//  OnboardingHealthVitalLevelsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import DataContainer

struct OnboardingHealthVitalLevelsView: View {
    let onContinue: () -> Void

    private let vitalsViewModel = VitalsViewModel.shared

    @State private var vitals = [VitalModel]()
    @State private var noDataVitals = [VitalModel]()

    @State private var showContinue = false
    @State private var didContinue = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Let's calculate your Vitals to see where you are on your health journey.")
                }
                .onboardingTextStyle()
                .fixedSize(horizontal: false, vertical: true)

                if vitals.isEmpty && noDataVitals.isEmpty {
                    CircularSpinnerView()
                        .foregroundStyle(.tint)
                        .horizontallyCentered()
                } else {
                    VStack(alignment: .leading) {
                        ForEach(vitals) { vital in
                            MiniVitalCell(vital: vital)
                                .transition(.scale)
                        }
                        if noDataVitals.isNotEmpty {
                            Text("Looks like we're missing some data. That's ok!")
                                .font(.title)
                                .bold()
                                .fontDesign(.rounded)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.blurReplace)

                            ForEach(noDataVitals) { vital in
                                MiniVitalCell(vital: vital)
                                    .transition(.scale)
                            }
                        }
                    }
                    .horizontalAlignment(.leading)
                }
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .topSafeAreaBlur()
        .animation(.bouncy, value: vitals.count)
        .animation(.bouncy, value: noDataVitals.count)
        .sensoryFeedback(.impact, trigger: vitals.count)
        .sensoryFeedback(.impact, trigger: noDataVitals.count)
        .sensoryFeedback(.selection, trigger: didContinue)
        .shelf {
            if showContinue {
                Button("So cool!") {
                    didContinue.toggle()
                    onContinue()
                }
                .buttonStyle(.onboarding)
            }
        }
        .task {
            await VitalsCalculator.shared.forceFetchVitals()
            await Delay(1000)
            await advanceVitals()
            await Delay(500)
            showContinue = true
        }
    }
}

private extension OnboardingHealthVitalLevelsView {

    func advanceVitals() async {
        await Delay(100)

        if vitals.count < vitalsViewModel.vitals.count {
            let index = vitals.count
            vitals.append(vitalsViewModel.vitals[index])
        } else if noDataVitals.count < vitalsViewModel.noDataVitals.count {
            let index = noDataVitals.count
            noDataVitals.append(vitalsViewModel.noDataVitals[index])
        } else {
            return
        }

        await advanceVitals()
    }
}

private struct VitalLevelView: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: systemImage)
                .font(.title)
                .bold()
                .foregroundStyle(.white, .tint)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .bold()

                Text(description)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardContainer()
    }
}

#Preview {
    OnboardingHealthVitalLevelsView { }
}
