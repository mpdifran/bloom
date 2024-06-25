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

                Circle()
                    .fill(.fill)
                    .frame(square: 40)
                    .overlay {
                        Circle()
                            .stroke(.tint, lineWidth: 2)
                    }
                    .overlay {
                        Image(systemName: directive.sfSymbol)
                            .foregroundStyle(.tint)
                            .symbolVariant(.fill)
                    }
            }
            .padding(.top)

            Text(directive.description)
                .foregroundStyle(.secondary)

            if let supplementDetails = directive.supplementDetails {
                Spacer()
                Text("\(supplementDetails.dosageAmount, specifier: "%.0f") \(supplementDetails.dosageUnit)")
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)

                if let dateDescription = supplementDetails.scheduleTimeComponent.formattedTimeUsingNow {
                    TimelineView(.everyMinute) { _ in
                        Text(dateDescription)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                Divider()

                DirectiveCompleteButton("Mark as Taken") {

                }
            } else if let activityDetails = directive.activityDetails {
                Spacer()

                Text("\(activityDetails.recommendedDurationMinutes) min")
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)

                if let dateDescription = activityDetails.proposedTimeComponent?.formattedTimeUsingNow {
                    TimelineView(.everyMinute) { _ in
                        Text(dateDescription)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                Divider()

                DirectiveCompleteButton("Mark as Complete") {

                }
            }

//            Divider()
//
//            Button(action: {
//
//            }, label: {
//                HStack {
//                    Label("Try Something Else", systemImage: "arrow.up.arrow.down")
//                    Spacer()
//                }
//            })
//            .frame(height: 44)
//            .foregroundStyle(.red)
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
                    sfSymbol: "pill",
                    supplementDetails: .init(
                        dosageAmount: 3,
                        dosageUnit: "mg",
                        scheduleTimeComponent: .init(hour: 22, minute: 30),
                        alertsUser: true
                    )
                )
            )
            .tint(.blue)
        }
        Section {
            DirectiveCell(
                directive: .init(
                    title: "Go for a walk today",
                    description: "Today is pretty sunny and warm. Why not take a walk on your lunch time?",
                    sfSymbol: "figure.walk",
                    activityDetails: .init(
                        recommendedDurationMinutes: 15,
                        proposedTimeComponent: .init(hour: 12, minute: 00)
                    )
                )
            )
            .tint(.green)
        }
    }
}
