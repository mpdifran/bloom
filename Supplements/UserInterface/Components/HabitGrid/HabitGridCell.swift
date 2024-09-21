//
//  HabitGridCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI

struct HabitGridCell: View {
    let isComplete: Bool?
    let isToday: Bool

    var body: some View {
        Group {
            RoundedRectangle(cornerRadius: 6)
                .fill(.tint.opacity(cellOpacity))
                .overlay {
                    if isToday, let isComplete {
                        if isComplete {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.background, lineWidth: 2)
                                .padding(2)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.tint, lineWidth: 2)
                        }
                    }
                }
        }
        .aspectRatio(contentMode: .fit)
    }
}

private extension HabitGridCell {

    var cellOpacity: Double {
        switch isComplete {
        case true: 1
        case false: 0.3
        default: 0.1
        }
    }
}

#Preview {
    VStack {
        HabitGridCell(isComplete: false, isToday: false)
        HabitGridCell(isComplete: false, isToday: true)
        HabitGridCell(isComplete: true, isToday: false)
        HabitGridCell(isComplete: true, isToday: true)
    }
    .frame(width: 20)
    .tint(.mutedBlue)
}
