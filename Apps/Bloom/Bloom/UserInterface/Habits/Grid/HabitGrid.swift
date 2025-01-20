//
//  HabitGrid.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI
import AppUI

private extension CGFloat {
  static let spacing: CGFloat = 4
  static let minCellWidth: CGFloat = 20
}

private extension Double {
  static let cellDelay: Double = 0.02
}

struct HabitGrid: View {
  let model: HabitGridModel

  private let weekdays = ["S", "M", "T", "W", "Th", "F", "S"]

  @State private var completionSensoryToggle = false

  var body: some View {
    GeometryReader { proxy in
      HStack(spacing: .spacing) {
        ForEachEnumerated(model.weeks) { (columnIndex, week) in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.weeks.count - columnIndex - 1) {
            VStack(spacing: .spacing) {
              ForEach(0 ..< 7) { rowIndex in
                HabitGridCell(
                  id: "\(week.id)-\(rowIndex)",
                  isComplete: week.isComplete.safeAccess(at: UInt(rowIndex)),
                  isToday: week.todayIndex == rowIndex
                )
                .transition(.scale)
                .animation(
                  .bouncy
                    .delay(delay(column: columnIndex, row: rowIndex, width: proxy.size.width)),
                  value: week.isComplete.safeAccess(at: UInt(rowIndex))
                )
              }
            }
          }
        }
        VStack(spacing: .spacing) {
          ForEachEnumeratedNoID(weekdays) { (_, weekday) in
            RoundedRectangle(cornerRadius: 6)
              .fill(.clear)
              .overlay {
                Text(weekday)
                  .font(.caption)
                  .bold()
                  .foregroundStyle(.secondary)
              }
              .aspectRatio(contentMode: .fit)
          }
        }
      }
      .sensoryFeedback(.selection, trigger: completionSensoryToggle)
      .onChange(of: model) { _, _ in
        delayedSensoryFeedback(proxy: proxy)
      }
    }
    .frame(height: height)
    .padding(.leading, .spacing)
  }
}

extension HabitGrid {

  var height: CGFloat {
    7 * .minCellWidth + 6 * .spacing
  }

  func delayedSensoryFeedback(proxy: GeometryProxy) {
    let maxColumns = recommendedMaxColumnCount(for: proxy.size.width)

    for columnIndex in 0 ..< model.weeks.count {
      guard maxColumns > (model.weeks.count - columnIndex - 1) else { continue }

      for rowIndex in 0 ..< 7 {
        guard model.weeks[columnIndex].isComplete.safeAccess(at: UInt(rowIndex)) == true else { continue }

        let delay = delay(column: columnIndex, row: rowIndex, width: proxy.size.width)

        Task {
          await Delay(Int(delay * 1000))

          await MainActor.run {
            completionSensoryToggle.toggle()
          }
        }
      }
    }
  }

  func delay(column: Int, row: Int, width: CGFloat) -> Double {
    let maxColumnCount = recommendedMaxColumnCount(for: width)
    let difference = model.weeks.count - maxColumnCount
    let shiftedColumn = column - difference

    guard shiftedColumn > 0 else { return 0 }

    return (Double(shiftedColumn) * Double.cellDelay * 2) + Double(row) * Double.cellDelay
  }

  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - .minCellWidth
    return Int((remainingWidth / (.minCellWidth + .spacing)).rounded(.towardZero))
  }
}

#Preview {
  @Previewable @State var habitGridModel = HabitGridModel()

  VStack {
    HabitGrid(model: habitGridModel)
      .padding(.spacing)

    HabitGrid(model: .init())
      .padding(.spacing)

    Spacer()
  }
  .tint(.mutedPink)
  .onAppear {
    withAnimation {
      habitGridModel = HabitGridModel(
        weeks: [
          .init(id: 16, isComplete: [false, true, true, false, false, true, false]),
          .init(id: 15, isComplete: [true, false, true, false, true, true, true]),
          .init(id: 14, isComplete: [false, true, true, false, false, true, true]),
          .init(id: 13, isComplete: [true, true, true, true, false, true, false]),
          .init(id: 12, isComplete: [false, false, true, false, false, true, true]),
          .init(id: 11, isComplete: [true, true, false, false, false, true, true]),
          .init(id: 10, isComplete: [false, true, true, false, false, false, true]),
          .init(id: 9, isComplete: [true, true, true, false, true, false, false]),
          .init(id: 8, isComplete: [false, true, false, false, false, false, false]),
          .init(id: 7, isComplete: [true, true, true, false, true, false, false]),
          .init(id: 6, isComplete: [true, true, true, false, true, true, true]),
          .init(id: 5, isComplete: [true, false, false, false, true, true, false]),
          .init(id: 4, isComplete: [false, true, true, false, false, true, false]),
          .init(id: 3, isComplete: [true, true, false, true, false, false, false]),
          .init(id: 2, isComplete: [true, false, false, true, false, true, true]),
          .init(id: 1, isComplete: [false, true, true, false, false, true, false]),
          .init(id: 0, isComplete: [true, true, false, true], todayIndex: 3),
        ]
      )
    }
  }
}
