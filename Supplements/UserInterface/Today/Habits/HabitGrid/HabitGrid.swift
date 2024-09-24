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
    static let cellDelay: Double = 0.01
}

struct HabitGrid: View {
    let model: HabitGridModel

    private let weekdays = ["S", "M", "T", "W", "Th", "F", "S"]

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
        }
        .frame(height: height)
        .padding(.leading, .spacing)
    }
}

extension HabitGrid {

    var height: CGFloat {
        7 * .minCellWidth + 6 * .spacing
    }

    func delay(column: Int, row: Int, width: CGFloat) -> Double {
        let maxColumnCount = recommendedMaxColumnCount(for: width)
        let difference = model.weeks.count - maxColumnCount
        let shiftedColumn = column - difference

        guard shiftedColumn > 0 else { return 0 }

        return (Double(shiftedColumn) * Double.cellDelay * 3) + Double(row) * Double.cellDelay
    }

    func recommendedMaxColumnCount(for width: CGFloat) -> Int {
        let remainingWidth = width - .minCellWidth
        return Int((remainingWidth / (.minCellWidth + .spacing)).rounded(.towardZero))
    }
}

#Preview {
    VStack {
        HabitGrid(
            model: .init(
                weeks: [
                    .init(id: 1, isComplete: [false, true, true, false, false, true, false]),
                    .init(id: 2, isComplete: [true, false, true, false, true, true, true]),
                    .init(id: 3, isComplete: [false, true, true, false, false, true, true]),
                    .init(id: 4, isComplete: [true, true, true, true, false, true, false]),
                    .init(id: 5, isComplete: [false, false, true, false, false, true, true]),
                    .init(id: 6, isComplete: [true, true, false, false, false, true, true]),
                    .init(id: 7, isComplete: [false, true, true, false, false, false, true]),
                    .init(id: 8, isComplete: [true, true, true, false, true, false, false]),
                    .init(id: 9, isComplete: [false, true, false, false, false, false, false]),
                    .init(id: 10, isComplete: [true, true, true, false, true, false, false]),
                    .init(id: 11, isComplete: [true, true, true, false, true, true, true]),
                    .init(id: 12, isComplete: [true, false, false, false, true, true, false]),
                    .init(id: 13, isComplete: [false, true, true, false, false, true, false]),
                    .init(id: 14, isComplete: [true, true, false, true, false, false, false]),
                    .init(id: 15, isComplete: [true, false, false, true, false, true, true]),
                    .init(id: 16, isComplete: [false, true, true, false, false, true, false]),
                    .init(id: 17, isComplete: [true, true, false, true], todayIndex: 3),
                ]
            )
        )
        .padding(.spacing)

        HabitGrid(model: .init())
            .padding(.spacing)

        Spacer()
    }
}
