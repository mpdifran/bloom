//
//  DirectiveCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import SwiftUI
import OpenAPIClient

struct DirectiveCell: View {
    let directive: UserDirective

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(directive.title)
                    .font(.title3)
                    .bold()

                Spacer()

                if let symbol = directive.sfSymbol {
                    Circle()
                        .fill(.fill)
                        .frame(square: 40)
                        .overlay {
                            Image(systemName: symbol)
                                .foregroundStyle(.tint)
                                .symbolVariant(.fill)
                        }
                }
            }

            Divider()

            Text(directive.description)
                .foregroundStyle(.secondary)

            Divider()

            Button(action: {

            }, label: {
                HStack {
                    if directive.kind == "scheduled" {
                        Label("Manage Schedule", systemImage: "calendar")
                    } else {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                    }
                    Spacer()
                }
            })
            .frame(height: 44)
            .foregroundStyle(.tint)

            Divider()

            Button(action: {

            }, label: {
                HStack {
                    Label("Try Something Else", systemImage: "arrow.up.arrow.down")
                    Spacer()
                }
            })
            .frame(height: 44)
            .foregroundStyle(.red)
        }
    }
}

#Preview {
    List {
        Section {
            DirectiveCell(
                directive: .init(
                    title: "Take melatonin nightly",
                    description: "Melatonin can help improve sleep quality. Let's try taking it every night for 2 weeks and monitor the results.",
                    kind: "scheduled",
                    sfSymbol: "pill"
                )
            )
            .tint(.blue)
        }
        Section {
            DirectiveCell(
                directive: .init(
                    title: "Go for a walk today",
                    description: "Today is pretty sunny and warm. Why not take a walk on your lunch time?",
                    kind: "one-time",
                    sfSymbol: "figure.walk"
                )
            )
            .tint(.green)
        }
    }
}
