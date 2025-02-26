//
//  HabitGridRowWeekLookbackView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI

private extension CGFloat {
  static let spacing: CGFloat = 4
  static let minCellWidth: CGFloat = 20
}

private extension Double {
  static let cellDelay: Double = 0.1
}

struct HabitGridRowWeekLookbackView: View {
  let completionHistory: [Bool]
  let animationDelay: Double

  init(
    completionHistory: [Bool],
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
          HabitGridCell(
            id: "\(index)",
            isComplete: completionHistory.safeAccess(at: UInt(index)),
            isToday: false
          )
          .frame(height: .minCellWidth)

          Text(weekdays.safeAccess(at: UInt(index)) ?? "")
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

  func calculateDelay(for index: Int) -> Double {
    Double(index) * Double.cellDelay
  }

  func delayedSensoryFeedback() {
    for index in 0 ..< 7 {
      guard completionHistory.safeAccess(at: UInt(index)) == true else { continue }

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
  @Previewable @State var completionHistory: [Bool] = []

  HabitGridRowWeekLookbackView(
    completionHistory: completionHistory,
    animationDelay: 1
  )
  .tint(.mutedPink)
  .onAppear {
    completionHistory = [true, false, false, true, true, false, true]
  }
}
