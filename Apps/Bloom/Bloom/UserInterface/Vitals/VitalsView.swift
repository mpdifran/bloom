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
import BloomUI

struct VitalsView: View {

  private let viewModel = VitalsViewModel.shared
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared
  @StateObject private var entitlementController = EntitlementController.shared

  @State private var path = NavigationPath()
  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @Environment(TabController.self) private var tabController: TabController

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    NavigationStack(path: $path) {
      BloomScrollView {
        // Only show biological age section if user doesn't have Pro (to show upsell)
        // or if they have Pro and the feature is enabled
        if entitlementController.hasBloomPro != true || aiFeatureSettings.biologicalAgeEnabled {
          SectionTitleView("Biological Age")
            .padding(.horizontal)

          bioAgeMeter
        }

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
      .animation(.default, value: aiFeatureSettings.biologicalAgeEnabled)
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
      // Only show biological age meter if the feature is enabled
      if aiFeatureSettings.biologicalAgeEnabled {
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
      }
    } else {
      BioAgeMeterGetBloomPlusCell {
        EntitledAction(presentedSheet: $presentedSheet, focus: .biologicalAge) {
          // Do nothing
        }
      }
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
