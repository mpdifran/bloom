//
//  TodayHeroCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI
import BloomModel
import CoreHealth

private extension CGFloat {
  static let budSize: CGFloat = 180
}

struct TodayHeroCell: View {
  let budState: TodayReportResponse.BudState?
  let summary: String?
  let hasError: Bool
  let onReload: (() async -> Void)?
  
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
      }

      if hasError {
        errorView
      } else if let summary {
        Text(summary)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
          .fixedSize(horizontal: false, vertical: true)
          .horizontalAlignment(.leading)
      } else {
        CircularSpinnerView()
          .foregroundStyle(.tint)
          .frame(minHeight: 80)
          .horizontallyCentered()
      }
    }
    .animation(.default, value: budState)
    .animation(.default, value: hasError)
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
    let currentMode = TimeMode.current(for: .now, settings: todaySettings)
    let userName = HealthManager.shared.name.isEmpty ? "there" : HealthManager.shared.name
    
    switch currentMode {
    case .morning:
      return "Good Morning, \(userName)!"
    case .afternoon:
      return "Good Afternoon, \(userName)!"
    case .evening:
      return "Good Evening, \(userName)!"
    case .night:
      return "Good Night, \(userName)!"
    }
  }

  var todaysDateView: some View {
    TimelineView(.everyMinute) { _ in
      Text("\(DateFormatter.weekdayFullMonthDayYear.string(from: .now))")
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
          budState: .proudCoach,
          summary: "You had a strong strength and protein day but overshot calories and sodium while not getting enough cardio or deep sleep.",
          hasError: false,
          onReload: nil
        )

        TodayHeroCell(
          budState: nil,
          summary: nil,
          hasError: false,
          onReload: nil
        )
        
        TodayHeroCell(
          budState: nil,
          summary: nil,
          hasError: true,
          onReload: {
            print("Reload tapped")
          }
        )
      }
      .navigationTitle("Today")
    }
  }
}
