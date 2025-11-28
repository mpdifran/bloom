//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI
import AppUI
import DataContainer
import CoreHealth

struct VitalsView: View {

  private let viewModel = VitalsViewModel.shared
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared
  @StateObject private var entitlementController = EntitlementController.shared

  @State private var path = NavigationPath()
  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    NavigationStack(path: $path) {
      BloomScrollView {
        SectionTitleView("Biological Age")
          .padding(.horizontal)

        bioAgeMeter

        if viewModel.vitals.isNotEmpty {
          SectionTitleView("Vitals")
            .padding(.horizontal)

          ForEach(viewModel.vitals) { vital in
            NavigationLink(value: vital.id) {
              MonthlyVitalCardCell(vital: vital)
            }
            .buttonStyle(.plain)
          }
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

        MedicalDisclaimerFooterView()
      }
      .navigationTitle("You")
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
        @unknown default:
          fatalError("Unknown case")
        }
      }
      .navigationDestination($presentedNavigationDestination)
      .sheet($presentedSheet)
      .animation(.default, value: viewModel.vitals)
      .toolbar {
        SettingsProfileViewToolbarButton()
        ToolbarItem(placement: .cancellationAction) {
          Button {
            presentedSheet = YouSettingsView().asAny
          } label: {
            Image(systemSymbol: .sliderHorizontal3)
              .bold()
          }
          .buttonStyle(.plain)
        }
      }
      .onChange(of: tabController.pendingVitalNavigation) { oldValue, newValue in
        if let vitalKind = newValue {
          path.append(vitalKind)
          tabController.pendingVitalNavigation = nil
        }
      }
    }
    .tabItem {
      Label("You", systemSymbol: .figure)
    }
  }
}

private extension VitalsView {

  @ViewBuilder
  var bioAgeMeter: some View {
    if entitlementController.hasBloomPro == true {
      VStack(spacing: 0) {
        BiologicalAgeMeter(
          biologicalAge: biologicalAgeViewModel.currentBiologicalAge
        )
        .frame(square: 200)

        Divider()

        Button {
          presentedNavigationDestination = BiologicalAgeDetailsView().asAny
        } label: {
          HStack {
            Text("View Details")
              .bold()
              .fontDesign(.rounded)

            Spacer()

            DisclosureIndicator()
          }
          .frame(height: 50)
          .selectable()
        }
        .buttonStyle(.plain)
      }
      .horizontallyCentered()
      .padding(.horizontal)
      .padding(.top)
      .cardContainer(includePadding: false)
    } else {
      BioAgeMeterGetBloomPlusCell()
    }
  }
}

#Preview {
  PreviewEnvironment {
    TabView {
      VitalsView()
    }
  }
}
