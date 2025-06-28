//
//  HabitGridWeek.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI
import AppUI

private extension CGFloat {
  static let spacing: CGFloat = 4
  static let minCellWidth: CGFloat = 20
  static let labelHeight: CGFloat = 20
}

private extension Double {
  static let cellDelay: Double = 0.02
}

struct HabitGridWeek: View {
  let model: HabitGridWeekModel

  @State private var completionSensoryToggle = false

  var body: some View {
    GeometryReader { proxy in
      HStack(alignment: .bottom, spacing: .spacing) {
        ForEachEnumerated(model.weeks) { (columnIndex, week) in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.weeks.count - columnIndex - 1) {
            VStack(spacing: 0) {
              if let monthLabel = week.monthLabel {
                Text(monthLabel)
                  .font(.caption)
                  .bold()
                  .foregroundStyle(.secondary)
                  .frame(height: .labelHeight, alignment: .bottom)
              } else {
                Color.clear
                  .frame(height: .labelHeight)
              }

              HabitGridWeekCell(
                id: "\(week.id)",
                isComplete: week.isComplete,
                isToday: week.isCurrentWeek
              )
              .transition(.scale)
              .animation(
                .bouncy
                  .delay(delay(column: columnIndex, width: proxy.size.width)),
                value: week.isComplete
              )
            }
          }
        }
      }
      .sensoryFeedback(.selection, trigger: completionSensoryToggle)
      .onChange(of: model) { _, _ in
        delayedSensoryFeedback(proxy: proxy)
      }
    }
    .frame(height: height)
    .padding(.horizontal, .spacing)
  }
}

extension HabitGridWeek {

  var height: CGFloat {
    let cellHeight = 7 * .minCellWidth + 6 * .spacing
    return cellHeight + .labelHeight
  }

  func delayedSensoryFeedback(proxy: GeometryProxy) {
    let maxColumns = recommendedMaxColumnCount(for: proxy.size.width)

    for columnIndex in 0 ..< model.weeks.count {
      guard maxColumns > (model.weeks.count - columnIndex - 1) else { continue }
      guard model.weeks[columnIndex].isComplete == true else { continue }

      let delay = delay(column: columnIndex, width: proxy.size.width)

      Task {
        await Delay(Int(delay * 1000))

        await MainActor.run {
          completionSensoryToggle.toggle()
        }
      }
    }
  }

  func delay(column: Int, width: CGFloat) -> Double {
    let maxColumnCount = recommendedMaxColumnCount(for: width)
    let difference = model.weeks.count - maxColumnCount
    let shiftedColumn = column - difference

    guard shiftedColumn > 0 else { return 0 }

    return Double(shiftedColumn) * Double.cellDelay * 2
  }

  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - .minCellWidth
    return Int((remainingWidth / (.minCellWidth + .spacing)).rounded(.towardZero))
  }
}

#Preview {
  @Previewable @State var habitGridWeekModel = HabitGridWeekModel()

  VStack {
    HabitGridWeek(model: habitGridWeekModel)
      .padding(.spacing)

    HabitGridWeek(model: HabitGridWeekModel())
      .padding(.spacing)

    Spacer()
  }
  .tint(.mutedPink)
  .onAppear {
    withAnimation {
      habitGridWeekModel = HabitGridWeekModel(
        weeks: [
          HabitGridWeekModel.Week(id: 20, isComplete: false),
          HabitGridWeekModel.Week(id: 19, isComplete: true),
          HabitGridWeekModel.Week(id: 18, isComplete: true),
          HabitGridWeekModel.Week(id: 17, isComplete: false),
          HabitGridWeekModel.Week(id: 16, isComplete: true),
          HabitGridWeekModel.Week(id: 15, isComplete: false),
          HabitGridWeekModel.Week(id: 14, isComplete: true, monthLabel: "Jul"),
          HabitGridWeekModel.Week(id: 13, isComplete: true),
          HabitGridWeekModel.Week(id: 12, isComplete: false),
          HabitGridWeekModel.Week(id: 11, isComplete: true),
          HabitGridWeekModel.Week(id: 10, isComplete: true),
          HabitGridWeekModel.Week(id: 9, isComplete: false),
          HabitGridWeekModel.Week(id: 8, isComplete: true),
          HabitGridWeekModel.Week(id: 7, isComplete: true, monthLabel: "Jun"),
          HabitGridWeekModel.Week(id: 6, isComplete: false),
          HabitGridWeekModel.Week(id: 5, isComplete: true),
          HabitGridWeekModel.Week(id: 4, isComplete: false),
          HabitGridWeekModel.Week(id: 3, isComplete: true),
          HabitGridWeekModel.Week(id: 2, isComplete: false),
          HabitGridWeekModel.Week(id: 1, isComplete: true),
          HabitGridWeekModel.Week(id: 0, isComplete: false, isCurrentWeek: true),
        ]
      )
    }
  }
}
