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
                isComplete: false,
                vitalKind: proposedToDo.vitalKind,
                useSecondaryBackground: false
            )
            .padding(4)

            Text(proposedToDo.context)
                .foregroundStyle(.white)
                .bold()
                .fixedSize(horizontal: false, vertical: true)
                .padding()
        }
        .cardContainer(fill: .tint, includePadding: false, cornerRadius: 30)
        .tint(proposedToDo.todoKind.color)
    }
}

#Preview {
    ScrollView {
        VStack {
            ProposedToDoCell(
                proposedToDo: ProposedToDo(
                    todoKind: .logFood,
                    todoCadence: .daily,
                    vitalKind: .nutrition,
                    context: "Bloom needs more data before it can suggest a habit. Please log your food for at least 7 days."
                )
            )
        }
        .padding()
    }
}
