//
//  HabitGridCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI

struct HabitGridCell: View {
    let id: String
    let isComplete: Bool?
    let isToday: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(.tint.opacity(strokeOpacity))
            .overlay {
                if let isComplete {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.tint.opacity(cellOpacity))
                        .overlay {
                            if isToday {
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
            }
            .aspectRatio(contentMode: .fit)
            .id(id)
    }
}

private extension HabitGridCell {

    var strokeOpacity: Double {
        switch isComplete {
        case .none: 0.4
        default: 0
        }
    }

    var cellOpacity: Double {
        switch isComplete {
        case true: 1
        case false: 0.4
        default: 0.4
        }
    }
}

#Preview {
    VStack {
        HabitGridCell(id: "1", isComplete: false, isToday: false)
        HabitGridCell(id: "2", isComplete: false, isToday: true)
        HabitGridCell(id: "3", isComplete: true, isToday: false)
        HabitGridCell(id: "4", isComplete: true, isToday: true)
        HabitGridCell(id: "5", isComplete: nil, isToday: false)
    }
    .frame(width: 20)
    .tint(.mutedBlue)
}
