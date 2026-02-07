//
//  ActiveWorkoutMetricsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI
import CoreHealth
import AppUI

private extension CGFloat {
  static let zoneBarHeight: CGFloat = 18
  static let zoneBarMaxWidth: CGFloat = 60
  static let dotInset: CGFloat = 2

  func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
    Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
  }
}

struct ActiveWorkoutMetricsView: View {
  @EnvironmentObject var workoutManager: WorkoutManager

  @State private var countdownIndex = 3
  @State private var presentedSheet: AnyView?

  var body: some View {
    Group {
      if countdownIndex >= 0 {
        countdownView
      } else {
        activeWorkoutContent
      }
    }
    .scenePadding()
    .animation(.default, value: workoutManager.heartRate)
    .animation(.default, value: workoutManager.totalZoneMinutes)
    .animation(.default, value: workoutManager.currentZone)
    .animation(.default, value: workoutManager.activeEnergy)
    .animation(.bouncy, value: countdownIndex)
    .sheet($presentedSheet)
    .task {
      // Skip countdown if workout is already running (returning to active workout)
      guard workoutManager.sessionState != .running && workoutManager.sessionState != .paused else {
        countdownIndex = -1
        return
      }

      // Count down: 3 → 2 → 1 → 0 (GO!) → -1 (active content)
      for i in (0...countdownIndex).reversed() {
        try? await Task.sleep(for: .seconds(1))
        countdownIndex = i - 1
      }
      try? await workoutManager.beginWorkout()
    }
  }

  func elapsedTime(with contextDate: Date) -> TimeInterval {
    return workoutManager.builder?.elapsedTime(at: contextDate) ?? 0
  }
}

private extension ActiveWorkoutMetricsView {

  var countdownView: some View {
    Text(countdownIndex > 0 ? "\(countdownIndex)" : "GO!")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .font(.system(size: 100))
      .fontDesign(.rounded)
      .fontWeight(.heavy)
      .foregroundStyle(.blue.gradient)
      .contentTransition(.numericText(value: Double(countdownIndex)))
      .removeCancellationToolbarItem()
  }

  var activeWorkoutContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      HeartRateZoneStatusView(
        heartRate: workoutManager.heartRate,
        zones: workoutManager.heartRateZones
      )

      Spacer()

      elapsedTimeView
      caloriesComponent
      zoneMinutesComponent
    }
    .horizontalAlignment(.leading)
    .toolbarVisibility(.hidden, for: .bottomBar)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        HStack {
          workoutTypeView
        }
        .fixedSize(horizontal: true, vertical: false)
      }
      ToolbarItem(placement: .topBarLeading) {
        HStack {
          workoutTypeView
        }
        .fixedSize(horizontal: true, vertical: false)
      }
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          presentedSheet = ActiveWorkoutControlsView().asAny
        } label: {
          Image(systemSymbol: .chevronDown)
            .bold()
            .fontDesign(.rounded)
        }
      }
    }
  }

  var backgroundColor: Color {
    switch workoutManager.currentZone {
    case 1:
        .heartRateZone1
    case 2:
        .heartRateZone2
    case 3:
        .heartRateZone3
    case 4:
        .heartRateZone4
    case 5:
        .heartRateZone5
    default:
        .black
    }
  }

  func color(for zone: Int) -> Color {
    switch zone {
    case 1:
        .heartRateZone1
    case 2:
        .heartRateZone2
    case 3:
        .heartRateZone3
    case 4:
        .heartRateZone4
    case 5:
        .heartRateZone5
    default:
        .white
    }
  }

  @ViewBuilder
  var workoutTypeView: some View {
    Image(systemSymbol: workoutManager.session?.workoutConfiguration.activityType.systemSymbol ?? .figureStand)
      .font(.title3)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.blue.gradient)
  }

  var workoutNameView: some View {
    Text(workoutManager.session?.workoutConfiguration.activityType.name ?? "")
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
      .lineLimit(1)
  }

  var caloriesComponent: some View {
    Text("\(workoutManager.activeEnergy.format(using: .noDecimalPlaces)) Cal")
      .font(.title2)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundStyle(.mutedPink)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .contentTransition(.numericText(value: workoutManager.activeEnergy))
  }

  var elapsedTimeView: some View {
    TimelineView(
      MetricsTimelineSchedule(
        from: workoutManager.session?.startDate ?? Date(),
        isPaused: workoutManager.sessionState == .paused
      )
    ) { context in
      ElapsedTimeView(
        elapsedTime: elapsedTime(with: context.date),
        showSubseconds: context.cadence == .live
      )
      .font(.title2)
      .foregroundStyle(.mutedYellow)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
    }
  }

  var zoneMinutesComponent: some View {
    let minutes = Int(workoutManager.totalZoneMinutes)
    return Text("\(minutes) Zone Min")
      .font(.title2)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.mutedGreen)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .contentTransition(.numericText(value: workoutManager.totalZoneMinutes))
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ActiveWorkoutMetricsView()
        .preview_startWorkout(activityType: .running)
    }
  }
}
