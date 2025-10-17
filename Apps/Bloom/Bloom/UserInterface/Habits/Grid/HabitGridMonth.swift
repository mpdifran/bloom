//
//  HabitGridMonth.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI
import AppUI
import BloomFoundation

private extension CGFloat {
  static let spacing: CGFloat = 4
  static let minCellWidth: CGFloat = 80
  static let labelHeight: CGFloat = 20
}

private extension Double {
  static let cellDelay: Double = 0.08
}

struct HabitGridMonth: View {
  let model: HabitGridMonthModel

  @State private var completionSensoryToggle = false

  var body: some View {
    GeometryReader { proxy in
      HStack(alignment: .bottom, spacing: .spacing) {
        ForEachEnumerated(model.months) { (columnIndex, month) in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.months.count - columnIndex - 1) {
            VStack(alignment: .leading, spacing: 0) {
              Text(month.monthLabel)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
                .frame(height: .labelHeight, alignment: .bottom)

              HabitGridMonthCell(
                id: "\(month.id)",
                isComplete: month.isComplete,
                isToday: month.isCurrentMonth
              )
              .transition(.scale)
              .animation(
                .bouncy
                  .delay(delay(column: columnIndex, width: proxy.size.width)),
                value: month.isComplete
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

extension HabitGridMonth {

  var height: CGFloat {
    let cellHeight = 7 * 20 + 6 * .spacing // Month cell height similar to week cell
    return cellHeight + .labelHeight
  }

  func delayedSensoryFeedback(proxy: GeometryProxy) {
    let maxColumns = recommendedMaxColumnCount(for: proxy.size.width)

    for columnIndex in 0 ..< model.months.count {
      guard maxColumns > (model.months.count - columnIndex - 1) else { continue }
      guard model.months[columnIndex].isComplete == true else { continue }

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
    let difference = model.months.count - maxColumnCount
    let shiftedColumn = column - difference

    guard shiftedColumn > 0 else { return 0 }

    return Double(shiftedColumn) * Double.cellDelay * 2
  }

  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - .minCellWidth
    return Int((remainingWidth / (.minCellWidth + .spacing)).rounded(.awayFromZero))
  }
}

#Preview {
  @Previewable @State var habitGridMonthModel = HabitGridMonthModel()

  VStack {
    HabitGridMonth(model: habitGridMonthModel)
      .padding(.spacing)

    HabitGridMonth(model: HabitGridMonthModel())
      .padding(.spacing)

    Spacer()
  }
  .tint(.mutedPink)
  .onAppear {
    withAnimation {
      habitGridMonthModel = HabitGridMonthModel(
        months: [
          HabitGridMonthModel.Month(id: 11, isComplete: false, monthLabel: "Dec"),
          HabitGridMonthModel.Month(id: 10, isComplete: true, monthLabel: "Nov"),
          HabitGridMonthModel.Month(id: 9, isComplete: true, monthLabel: "Oct"),
          HabitGridMonthModel.Month(id: 8, isComplete: false, monthLabel: "Sep"),
          HabitGridMonthModel.Month(id: 7, isComplete: true, monthLabel: "Aug"),
          HabitGridMonthModel.Month(id: 6, isComplete: false, monthLabel: "Jul"),
          HabitGridMonthModel.Month(id: 5, isComplete: true, monthLabel: "Jun"),
          HabitGridMonthModel.Month(id: 4, isComplete: true, monthLabel: "May"),
          HabitGridMonthModel.Month(id: 3, isComplete: false, monthLabel: "Apr"),
          HabitGridMonthModel.Month(id: 2, isComplete: true, monthLabel: "Mar"),
          HabitGridMonthModel.Month(id: 1, isComplete: false, monthLabel: "Feb"),
          HabitGridMonthModel.Month(id: 0, isComplete: false, isCurrentMonth: true, monthLabel: "Jan"),
        ]
      )
    }
  }
}
