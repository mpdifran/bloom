//
//  ProposedToDoCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import SwiftUI

struct ProposedToDoCell: View {
    let proposedToDo: ProposedToDo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToDoActionCell(
                title: proposedToDo.todoKind.name,
                subtitle: proposedToDo.todoCadence.name,
                systemImage: proposedToDo.todoKind.systemImage,
                isComplete: false
            )

            Text(proposedToDo.context)
                .foregroundStyle(.tint)
                .bold()
                .padding()
        }
        .cardContainer(fill: .tint.tertiary, includePadding: false)
        .tint(proposedToDo.todoKind.color)
    }
}

#Preview {
    ScrollView {
        VStack {
            ProposedToDoCell(
                proposedToDo: .init(
                    todoKind: .logFood,
                    todoCadence: .daily,
                    context: "Bloom needs more data before it can suggest a habit. Please log your food for at least 7 days."
                )
            )
        }
        .padding()
    }
    .groupedBackground()
}
