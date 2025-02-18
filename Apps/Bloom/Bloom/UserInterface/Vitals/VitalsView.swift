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

  private let viewModel = VitalsViewModel.shared

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

          if viewModel.noDataVitals.isNotEmpty {
            SectionTitleView("No Data")
              .padding(.horizontal)
            ForEach(viewModel.noDataVitals) { vital in
              NavigationLink(value: vital.id) {
                MonthlyVitalCardCell(vital: vital)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .horizontallyCentered()
        .padding()
      }
      .tabBar()
      .groupedBackground()
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
        @unknown default:
          fatalError("Unknown case")
        }
      }
      .animation(.default, value: viewModel.vitals)
    }
  }
}

#Preview {
  TabView {
    VitalsView()
  }
}
