//
//  GoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct GoalCell: View {
    let goal: GoalModel
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(goal.name)
                .font(.title2)
                .bold()

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .contentTransition(.symbolEffect)
                .imageScale(.large)
        }
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(goal.color)
        }
    }
}

#Preview {
    List {
        GoalCell(
            goal: .init(name: "Brain Health", color: Color(hex: 0xff6361)),
            isSelected: true
        )
        GoalCell(
            goal: .init(name: "Build Muscle Mass", color: Color(hex: 0x8a508f)),
            isSelected: false
        )
    }
}
