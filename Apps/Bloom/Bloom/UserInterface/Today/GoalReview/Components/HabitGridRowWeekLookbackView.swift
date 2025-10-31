//
//  HabitGridRowWeekLookbackView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import BloomFoundation
import BloomUI

private extension CGFloat {
  static let spacing: CGFloat = 4
  static let minCellWidth: CGFloat = 20
}

private extension Double {
  static let cellDelay: Double = 0.1
}

struct HabitGridRowWeekLookbackView: View {
  let completionHistory: [HabitGoalMetSample]
  let animationDelay: Double

  init(
    completionHistory: [HabitGoalMetSample],
    animationDelay: Double = 0
  ) {
    self.completionHistory = completionHistory
    self.animationDelay = animationDelay
  }

  @State private var completionSensoryToggle = false

  private let weekdays = ["S", "M", "T", "W", "Th", "F", "S"]

  var body: some View {
    HStack(spacing: .spacing) {
      ForEach(0 ..< 7) { index in
        VStack(spacing: .spacing) {
          GoalGridCell(
            id: "\(index)",
            isComplete: completionHistory.safeAccess(at: UInt(index))?.goalMet,
            isToday: false,
            cornerRadius: 6
          )
          .frame(height: .minCellWidth)

          Text(weekdayName(for: completionHistory.safeAccess(at: UInt(index))?.date))
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
        }
        .transition(.scale)
        .animation(
          .bouncy
            .delay(calculateDelay(for: index)),
          value: completionHistory.safeAccess(at: UInt(index))
        )
      }
    }
    .sensoryFeedback(.selection, trigger: completionSensoryToggle)
    .onChange(of: completionHistory) { _, _ in
      delayedSensoryFeedback()
    }
  }
}

private extension HabitGridRowWeekLookbackView {

  func weekdayName(for date: Date?) -> String {
    guard let date = date else { return "" }

    let weekday = Calendar.current.component(.weekday, from: date)
    return weekdays.safeAccess(at: UInt(weekday - 1)) ?? ""
  }

  func calculateDelay(for index: Int) -> Double {
    Double(index) * Double.cellDelay
  }

  func delayedSensoryFeedback() {
    for index in 0 ..< 7 {
      guard completionHistory.safeAccess(at: UInt(index))?.goalMet == true else { continue }

      let delay = calculateDelay(for: index)

      Task {
        await Delay(Int(delay * 1000))

        await MainActor.run {
          completionSensoryToggle.toggle()
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var completionHistory: [HabitGoalMetSample] = []

  HabitGridRowWeekLookbackView(
    completionHistory: completionHistory,
    animationDelay: 1
  )
  .tint(.mutedPink)
  .onAppear {
    completionHistory = [
      HabitGoalMetSample(date: Date().addingTimeInterval(-518_400), goalMet: false),
      HabitGoalMetSample(date: Date().addingTimeInterval(-432_000), goalMet: true),
      HabitGoalMetSample(date: Date().addingTimeInterval(-345_600), goalMet: true),
      HabitGoalMetSample(date: Date().addingTimeInterval(-259_200), goalMet: false),
      HabitGoalMetSample(date: Date().addingTimeInterval(-172_800), goalMet: true),
      HabitGoalMetSample(date: Date().addingTimeInterval(-86_400), goalMet: false),
      HabitGoalMetSample(date: Date(), goalMet: true)
    ]
  }
}
