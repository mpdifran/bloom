//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI
import AppUI
import DataContainer

struct VitalsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack {
                    ForEach(viewModel.vitals) { vital in
                        NavigationLink(value: vital.id) {
                            MonthlyVitalCardCell(vital: vital)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .navigationTitle("Vitals")
            .navigationDestination(for: VitalModel.Kind.self) { vitalKind in
                switch vitalKind {
                case .sleepQuality: SleepDetailsView()
                case .bodyComposition: BodyCompositionDetailsView()
                case .nutrition: NutritionDetailsView()
                case .stressLevels: StressDetailsView()
                case .activityLevel: ActivityLevelDetailsView()
                case .heartHealth, .cardioFitness: HeartHealthDetailsView()
                case .exerciseEffectiveness: ExerciseEffectivenessView()
                case .cycleTracking: MenstruationDetailView()
                case .bowelMovements: BowelMovementsDetailView()
//                default: Text("Not Yet Implemented").navigationTitle(vitalKind.name)
                }
            }
            .animation(.default, value: viewModel.vitals)
            .groupedBackground()
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
