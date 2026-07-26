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

  @State private var presentedNavigationDestination: AnyView?
  @State private var presentedSheet: AnyView?

  @Environment(TabController.self) private var tabController: TabController

  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var healthManager = HealthManager.shared

  var body: some View {
    NavigationStack {
      BloomScrollView {
        bioAgeMeter

        MonitorSummarySection(presentedNavigationDestination: $presentedNavigationDestination)

        // Stat sections in user-defined order
        ForEach(youSettings.sectionOrder, id: \.self) { section in
          sectionView(for: section)
        }

        MedicalDisclaimerFooterView()
      }
      .navigationTitle("You")
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
          switch vitalKind {
          case .sleepQuality: presentedNavigationDestination = SleepDetailsView().asAny
          case .bodyComposition: presentedNavigationDestination = BodyCompositionDetailsView().asAny
          case .nutrition: presentedNavigationDestination = NutritionDetailsView().asAny
          case .stressLevels: presentedNavigationDestination = StressDetailsView().asAny
          case .activityLevel: presentedNavigationDestination = ActivityLevelDetailsView().asAny
          case .heartHealth, .cardioFitness: presentedNavigationDestination = HeartHealthDetailsView().asAny
          case .exerciseEffectiveness: presentedNavigationDestination = ExerciseEffectivenessView().asAny
          case .cycleTracking: presentedNavigationDestination = MenstruationDetailView().asAny
          case .bowelMovements: presentedNavigationDestination = BowelMovementsDetailView().asAny
          case .lifestyle: presentedNavigationDestination = AlcoholDetailsView().asAny
          @unknown default:
            break
          }
          tabController.pendingVitalNavigation = nil
        }
      }
      .onChange(of: tabController.pendingStepsNavigation) { _, shouldNavigate in
        if shouldNavigate {
          tabController.pendingStepsNavigation = false
          presentedNavigationDestination = MobilityDetailsView().asAny
        }
      }
      .onChange(of: tabController.pendingMonitorNavigation) { _, newValue in
        if let monitorType = newValue {
          presentedNavigationDestination = MonitorView(initialDetail: monitorType).asAny
          tabController.pendingMonitorNavigation = nil
        }
      }
    }
  }

  @ViewBuilder
  private func sectionView(for section: VitalModel.Kind) -> some View {
    switch section {
    case .sleepQuality:
      SleepQualitySection(
        presentedNavigationDestination: $presentedNavigationDestination,
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
        activeEnergyChartData: viewModel.activeEnergyChartData,
        walkingSpeedChartData: viewModel.walkingSpeedChartData,
        stairClimbSpeedChartData: viewModel.stairClimbSpeedChartData
      )
    case .heartHealth:
      HeartHealthSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        averageRestingHeartRate: viewModel.averageRestingHeartRate,
        heartRateReserveChartData: viewModel.heartRateReserveChartData,
        vo2MaxTrendData: viewModel.vo2MaxTrendData,
        heartRateRecoveryData: viewModel.heartRateRecoveryData,
        restingHeartRateChartData: viewModel.restingHeartRateChartData
      )
    case .bodyComposition:
      BodyCompositionSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        bodyFatPercentage: viewModel.bodyFatPercentage,
        bodyWeightChartData: viewModel.bodyWeightChartData
      )
    case .stressLevels:
      StressLevelsSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        hrvChartData: viewModel.hrvChartData,
        bloodPressureData: viewModel.bloodPressureData
      )
    case .nutrition:
      NutritionSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        macros: viewModel.nutritionMacros,
        fiberChartData: viewModel.fiberChartData,
        sugarChartData: viewModel.sugarChartData
      )
    case .lifestyle:
      LifestyleSection(
        presentedNavigationDestination: $presentedNavigationDestination,
        alcoholSummary: viewModel.alcoholSummary,
        smokingStatus: healthManager.smokingStatus,
        smokingQuitDate: healthManager.smokingQuitDate
      )
    case .exerciseEffectiveness:
      ExerciseEffectivenessSection(
        presentedNavigationDestination: $presentedNavigationDestination,
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
