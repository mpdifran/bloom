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
      .font(.system(size: 100))
      .fontDesign(.rounded)
      .fontWeight(.heavy)
      .foregroundStyle(.tint)
      .contentTransition(.numericText(value: Double(countdownIndex)))
      .removeCancellationToolbarItem()
  }

  var activeWorkoutContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()

      zoneNameView
      heartRateComponent
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
          workoutNameView
        }
        .fixedSize(horizontal: true, vertical: false)
      }
      ToolbarItem(placement: .topBarLeading) {
        HStack {
          workoutTypeView
          workoutNameView
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
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
  }

  var workoutNameView: some View {
    Text(workoutManager.session?.workoutConfiguration.activityType.name ?? "")
      .font(.headline)
      .bold()
      .fontDesign(.rounded)
      .lineLimit(1)
  }

  @ViewBuilder
  var zoneBarComponent: some View {
    if workoutManager.currentZone < 1 {
      Text("Warming Up")
        .foregroundStyle(backgroundColor)
        .font(.caption2)
        .bold()
        .padding(.horizontal, 8)
        .background {
          Capsule()
            .fill(.tint)
            .frame(height: .zoneBarHeight)
        }
    } else {
      HStack(spacing: 2) {
        ForEach(1...5, id: \.self) { zone in
          let isCurrentZone = zone == workoutManager.currentZone

          Capsule()
            .fill(isCurrentZone ? color(for: zone) : .white)
            .frame(
              width: isCurrentZone ? .zoneBarMaxWidth : .zoneBarHeight,
              height: .zoneBarHeight
            )
            .overlay {
              if isCurrentZone {
                GeometryReader { geometry in
                  Circle()
                    .fill(.black)
                    .frame(square: .zoneBarHeight - .dotInset * 2)
                    .position(
                      x: dotXPosition(in: geometry.size.width),
                      y: geometry.size.height / 2
                    )
                }
              }
            }
        }
      }
    }
  }

  var zoneNameView: some View {
    Group {
      if workoutManager.currentZone > 0 {
        Text("Zone \(workoutManager.currentZone)")
      } else {
        Text("Warming Up")
      }
    }
    .foregroundStyle(.black)
    .font(.system(size: 10))
    .bold()
    .fontDesign(.rounded)
    .lineLimit(1)
    .padding(.vertical, 2)
    .padding(.horizontal, 6)
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(color(for: workoutManager.currentZone))
    }
  }

  var zoneProgress: CGFloat {
    guard let zones = workoutManager.heartRateZones else { return 0.5 }
    let hr = workoutManager.heartRate
    let zone = workoutManager.currentZone

    let (lower, upper): (Double, Double) = switch zone {
    case 1: (zones.zone1, zones.zone2)
    case 2: (zones.zone2, zones.zone3)
    case 3: (zones.zone3, zones.zone4)
    case 4: (zones.zone4, zones.zone5)
    case 5: (zones.zone5, zones.maxHeartRate)
    default: (0, 1)
    }

    guard upper > lower else { return 0.5 }
    return CGFloat((hr - lower) / (upper - lower)).clamped(to: 0...1)
  }

  func dotXPosition(in width: CGFloat) -> CGFloat {
    let dotRadius: CGFloat = (.zoneBarHeight - 4) / 2
    let minX = dotRadius + .dotInset
    let maxX = width - dotRadius - .dotInset
    return minX + ((maxX - minX) * zoneProgress)
  }

  var heartRateComponent: some View {
    HStack {
      Image(systemSymbol: .heartFill)
        .font(.caption)
        .symbolEffect(.bounce, options: .repeating.speed(workoutManager.heartRate / 60.0))
        .foregroundStyle(.mutedRed)

      HStack(alignment: .firstTextBaseline) {
        Text(workoutManager.heartRate.format(using: .noDecimalPlaces))
          .contentTransition(.numericText(value: workoutManager.heartRate))

        Text("BPM")
          .font(.caption2)
          .bold()
          .fontDesign(.rounded)
      }
    }
    .font(.title2)
    .fontWeight(.bold)
    .fontDesign(.rounded)
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
