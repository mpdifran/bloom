//
//  TodayHeroCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI
import BloomModel
import BloomUI
import CoreHealth

private extension CGFloat {
  static let budSize: CGFloat = 240
}

struct TodayHeroCell: View {
  let budState: TodayReportResponse.BudState?
  let summary: String?
  let hasError: Bool
  let isLoading: Bool
  let onReload: (() async -> Void)?
  /// Overrides the name from HealthManager. Used by the App Store screenshot previews, which show
  /// a fictional person rather than whoever is signed in on the capturing machine.
  let nameOverride: String?
  /// Overrides "now" for the greeting and the date. Also for the screenshot previews, so a capture
  /// doesn't say "Good Night" because of when it happened to be taken.
  let dateOverride: Date?

  init(
    budState: TodayReportResponse.BudState?,
    summary: String?,
    hasError: Bool,
    isLoading: Bool,
    onReload: (() async -> Void)? = nil,
    nameOverride: String? = nil,
    dateOverride: Date? = nil
  ) {
    self.budState = budState
    self.summary = summary
    self.hasError = hasError
    self.isLoading = isLoading
    self.onReload = onReload
    self.nameOverride = nameOverride
    self.dateOverride = dateOverride
  }
  
  @TodaySettingsStorage("TodayView.settings") private var todaySettings = TodaySettings()

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      budStateView
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading) {
        todaysDateView
        Text(greetingText)
          .font(.title)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
      }

      if hasError {
        errorView
      } else if isLoading {
        ProgressView()
          .progressViewStyle(.circular)
          .frame(minHeight: 80)
          .horizontallyCentered()
      } else if let summary {
        Text(summary)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
          .fixedSize(horizontal: false, vertical: true)
          .horizontalAlignment(.leading)
      }
    }
    .animation(.default, value: budState)
    .animation(.default, value: hasError)
    .animation(.default, value: isLoading)
  }
}

private extension TodayHeroCell {
  
  var errorView: some View {
    VStack(spacing: 16) {
      Text("Whoops, looks like I made a mistake. Let's try that again...")
        .font(.title3)
        .fontDesign(.rounded)
        .bold()
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)

      if let onReload {
        AsyncButton {
          await onReload()
        } label: {
          Text("Try Again")
        }
        .buttonStyle(.tertiary)
      }
    }
    .frame(minHeight: 80)
  }
  
  var greetingText: String {
    let currentMode = TimeMode.current(for: dateOverride ?? .now, settings: todaySettings)
    let name = nameOverride ?? HealthManager.shared.name

    guard name.isNotEmpty else {
      switch currentMode {
      case .morning:
        return String(localized: "Good Morning!", comment: "Today screen greeting, no name known")
      case .afternoon:
        return String(localized: "Good Afternoon!", comment: "Today screen greeting, no name known")
      case .evening:
        return String(localized: "Good Evening!", comment: "Today screen greeting, no name known")
      case .night:
        return String(localized: "Good Night!", comment: "Today screen greeting, no name known")
      @unknown default:
        return String(localized: "Hello!", comment: "Today screen greeting, no name known")
      }
    }

    switch currentMode {
    case .morning:
      return String(localized: "Good Morning, \(name)!", comment: "Today screen greeting, %@ is the person's first name")
    case .afternoon:
      return String(localized: "Good Afternoon, \(name)!", comment: "Today screen greeting, %@ is the person's first name")
    case .evening:
      return String(localized: "Good Evening, \(name)!", comment: "Today screen greeting, %@ is the person's first name")
    case .night:
      return String(localized: "Good Night, \(name)!", comment: "Today screen greeting, %@ is the person's first name")
    @unknown default:
      return String(localized: "Hello, \(name)!", comment: "Today screen greeting, %@ is the person's first name")
    }
  }

  var todaysDateView: some View {
    TimelineView(.everyMinute) { _ in
      // Formatted by SwiftUI rather than a fixed DateFormatter, so it follows the environment's
      // locale - which is what makes a French screenshot show a French date.
      Text(dateOverride ?? .now, format: .dateTime.weekday(.wide).month(.wide).day().year())
        .font(.subheadline)
        .fontDesign(.rounded)
        .bold()
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
    }
  }

  var budStateView: some View {
    Group {
      if hasError {
        BudImage(.budStressed, dimension: .budSize)
      } else if let budState {
        switch budState {
        case .groggy:
          BudImage(.budGroggy, dimension: .budSize)
        case .sleepy:
          BudImage(.budSleepy, dimension: .budSize)
        case .eatingSalad:
          BudImage(.budSalad, dimension: .budSize)
        case .holdingSmoothie:
          BudImage(.budSmoothie, dimension: .budSize)
        case .holdingTrophy:
          BudImage(.budTrophy, dimension: .budSize)
        case .workingOut:
          BudImage(.budWorkout, dimension: .budSize)
        case .stressed:
          BudImage(.budStressed, dimension: .budSize)
        case .proudCoach:
          BudImage(.budCoach, dimension: .budSize)
        case .superhero:
          BudImage(.budSuperhero, dimension: .budSize)
        case .running:
          BudImage(.budRunning, dimension: .budSize)
        case .strengthTraining:
          BudImage(.budStrengthTraining, dimension: .budSize)
        case .yoga:
          BudImage(.budYoga, dimension: .budSize)
        case .bicycleRiding:
          BudImage(.budBicycle, dimension: .budSize)
        @unknown default:
          BudImage(.budCoach, dimension: .budSize)
        }
      } else {
        BudImage(.budThinking, dimension: .budSize)
      }
    }
    .horizontallyCentered()
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BloomScrollView {
        TodayHeroCell(
          budState: .bicycleRiding,
          summary: "You had a strong strength and protein day but overshot calories and sodium while not getting enough cardio or deep sleep.",
          hasError: false,
          isLoading: false
        )

        TodayHeroCell(
          budState: nil,
          summary: nil,
          hasError: false,
          isLoading: true
        )
        
        TodayHeroCell(
          budState: .superhero,
          summary: nil,
          hasError: false,
          isLoading: false
        )
        
        TodayHeroCell(
          budState: nil,
          summary: nil,
          hasError: true,
          isLoading: false,
          onReload: {
            print("Reload tapped")
          }
        )
      }
      .navigationTitle("Today")
    }
  }
}
