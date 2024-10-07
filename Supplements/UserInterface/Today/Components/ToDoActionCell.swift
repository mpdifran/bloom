//
//  ToDoActionCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI

struct ToDoActionCell: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isComplete: Bool

    var body: some View {
        HStack {
            CompletionCheckmarkView(state: isComplete ? .metGoal : .unmetGoal)

            LabeledContent {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            } label: {
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundStyle(.tint)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .bold()

            Spacer()
        }
        .cardContainer()
    }
}

#Preview {
    ScrollView {
        VStack {
            ToDoActionCell(
                title: "Log Weight",
                subtitle: "Daily",
                systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
                isComplete: false
            )
            .tint(.indigo)
            ToDoActionCell(
                title: "Log Weight",
                subtitle: "Daily",
                systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
                isComplete: true
            )
            .tint(.blue)
        }
        .horizontallyCentered()
        .padding()
    }
    .gradientRootBackground()
}
