//
//  TodayHeroCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI
import BloomModel

private extension CGFloat {
  static let budSize: CGFloat = 180
}

struct TodayHeroCell: View {
  let budState: TodayReportResponse.BudState?
  let summary: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      budStateView

      VStack(alignment: .leading) {
        todaysDateView
        Text("Good Morning, Mark!")
          .font(.title)
          .bold()
          .fontDesign(.rounded)
      }

      if let summary {
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
    .cardContainer()
    .animation(.default, value: budState)
  }
}

private extension TodayHeroCell {

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
      if let budState {
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
        case .coach:
          BudImage(.budCoach, dimension: .budSize)
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
          budState: .stressed,
          summary: "You had a strong strength and protein day but overshot calories and sodium while not getting enough cardio or deep sleep."
        )

        TodayHeroCell(
          budState: nil,
          summary: nil
        )
      }
      .navigationTitle("Today")
    }
  }
}
