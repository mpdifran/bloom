//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI

struct VitalsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack {
//                        VitalSummaryView(
//                            hrvStatus: viewModel.hrvStatus,
//                            sleepStatus: viewModel.sleepStatus,
//                            rhrStatus: viewModel.rhrStatus
//                        )
//                        .padding(.horizontal)
//
//                        HStack {
//                            Text("Monthly Vitals")
//                                .font(.headline)
//                                .bold()
//                            Spacer()
//                        }
//                        .padding(.top)
//                        .padding(.horizontal)
//                        .padding(.horizontal)

                        ForEach(viewModel.vitals) { vital in
                            NavigationLink(value: vital.id) {
                                MonthlyVitalCardCell(vital: vital)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom)
            }
            .navigationTitle("Vitals")
            .navigationDestination(for: VitalModel.Kind.self) { vitalKind in
                switch vitalKind {
                case .sleepQuality: SleepDetailsView()
                case .bodyComposition: BodyCompositionDetailsView()
                case .nutrition: NutritionDetailsView()
                case .stressLevels: StressDetailsView()
                case .activityLevel: ActivityLevelDetailsView()
                case .cardioFitness: CardioFitnessDetailsView()
                default: Text("Not Yet Implemented").navigationTitle(vitalKind.name)
                }
            }
            .animation(.default, value: viewModel.hrvStatus)
            .animation(.default, value: viewModel.sleepStatus)
            .animation(.default, value: viewModel.rhrStatus)
            .animation(.default, value: viewModel.vitals)
        }
        .tabItem {
            Label("Vitals", systemImage: "bolt.heart")
        }
    }
}

#Preview {
    TabView {
        VitalsView()
    }
}
