//
//  YouView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI
import AppUI
import DataContainer
import CoreHealth
import BloomUI

struct YouView: View {

  @State private var viewModel = YouStatsViewModel.shared
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared
  @StateObject private var entitlementController = EntitlementController.shared
  @YouSettingsStorage("YouView.settings") private var youSettings = YouSettings()

  @State private var path = NavigationPath()
  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @Environment(TabController.self) private var tabController: TabController

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    NavigationStack(path: $path) {
      BloomScrollView {
        bioAgeMeter

        // Stat sections in user-defined order
        ForEach(youSettings.sectionOrder, id: \.self) { section in
          sectionView(for: section)
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

  @ViewBuilder
  private func sectionView(for section: VitalModel.Kind) -> some View {
    switch section {
    case .sleepQuality:
      SleepQualitySection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.sleepVitalsSummary,
        bedtimeData: viewModel.bedtimeChartData,
        sleepDurationChartData: viewModel.sleepDurationChartData,
        averageSleepScore: viewModel.averageSleepScore,
        sleepStageDataPoints: viewModel.sleepStageDataPoints,
        averageSleepHeartRate: viewModel.averageSleepHeartRate,
        sleepHeartRateChartData: viewModel.sleepHeartRateChartData,
        sleepRespiratoryRateTrend: viewModel.sleepRespiratoryRateTrend,
        sleepRespiratoryRateChartData: viewModel.sleepRespiratoryRateChartData,
        wristTempData: viewModel.wristTempData
      )
    case .activityLevel:
      ActivityLevelSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.activityLevelSummary,
        weeklyStepsChartData: viewModel.weeklyStepsChartData,
        activeEnergyChartData: viewModel.activeEnergyChartData
      )
    case .heartHealth:
      HeartHealthSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.heartHealthSummary,
        heartRateReserveChartData: viewModel.heartRateReserveChartData,
        vo2MaxTrendData: viewModel.vo2MaxTrendData,
        heartRateRecoveryData: viewModel.heartRateRecoveryData
      )
    case .bodyComposition:
      BodyCompositionSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.bodyCompositionSummary,
        bodyWeightChartData: viewModel.bodyWeightChartData
      )
    case .stressLevels:
      StressLevelsSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.stressSummary,
        hrvChartData: viewModel.hrvChartData,
        bloodPressureData: viewModel.bloodPressureData
      )
    case .nutrition:
      NutritionSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.nutritionSummary,
        fiberChartData: viewModel.fiberChartData,
        sugarChartData: viewModel.sugarChartData
      )
    case .exerciseEffectiveness:
      ExerciseEffectivenessSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.exerciseEffectivenessSummary,
        zoneMinutesData: viewModel.zoneMinutesData,
        zoneDistributionData: viewModel.zoneDistributionData,
        recentWorkoutsData: viewModel.recentWorkoutsData
      )
    case .cycleTracking:
      if shouldShowCycleTracking {
        CycleTrackingSection(
          presentedNavigationDestination: $presentedNavigationDestination,
          summary: viewModel.menstrualSummary
        )
      }
    case .bowelMovements:
      BowelMovementsSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        summary: viewModel.bowelMovementSummary
      )
    case .cardioFitness:
      EmptyView() // Deprecated
    @unknown default:
      EmptyView()
    }
  }

  private var shouldShowCycleTracking: Bool {
    HealthManager.shared.sex() == .female
  }
}

private extension YouView {

  @ViewBuilder
  var bioAgeMeter: some View {
    YouHeaderView()
      .onTapGesture {
        presentedNavigationDestination = BiologicalAgeDetailsView().asAny
      }
  }
}

#Preview {
  PreviewEnvironment {
    TabView {
      YouView()
    }
  }
}
