//
//  DirectiveCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import SwiftUI
import OpenAPIClient

struct DirectiveCell: View {
    let sleepActivity: SleepActivityModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(sleepActivity.title)
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
                        Image(systemName: "figure.run")//sleepActivity.sfSymbol)
                            .foregroundStyle(.tint)
                            .symbolVariant(.fill)
                    }
            }
            .padding(.top)

            Text(sleepActivity.description)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Revisit on \(sleepActivity.revisitDate, formatter: DateFormatter.justDateMedium)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .horizontallyCentered()

//            if let supplementDetails = sleepActivity.supplementDetails {
//                Spacer()
//                Text("\(supplementDetails.dosageAmount, specifier: "%.0f") \(supplementDetails.dosageUnit)")
//                    .font(.title)
//                    .bold()
//                    .fontDesign(.rounded)
//
//                if let dateDescription = supplementDetails.scheduleTimeComponent.formattedTimeUsingNow {
//                    TimelineView(.everyMinute) { _ in
//                        Text(dateDescription)
//                            .foregroundStyle(.secondary)
//                            .font(.subheadline)
//                    }
//                }
//
//                Divider()
//
//                DirectiveCompleteButton("Mark as Taken") {
//
//                }
//            } else if let activityDetails = sleepActivity.activityDetails {
//                Spacer()
//
//                Text("\(activityDetails.recommendedDurationMinutes) min")
//                    .font(.title)
//                    .bold()
//                    .fontDesign(.rounded)
//
//                if let dateDescription = activityDetails.proposedTimeComponent?.formattedTimeUsingNow {
//                    TimelineView(.everyMinute) { _ in
//                        Text(dateDescription)
//                            .foregroundStyle(.secondary)
//                            .font(.subheadline)
//                    }
//                }
//
//                Divider()
//
//                DirectiveCompleteButton("Mark as Complete") {
//
//                }
//            }

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
                sleepActivity: .init(
                    title: "Take melatonin nightly",
                    description: "Melatonin can help improve sleep quality. Let's try taking it every night for 2 weeks and monitor the results.",
                    targetMetric: "deep_sleep",
                    startDate: .now,
                    revisitDate: Date(timeIntervalSinceNow: 12400),
                    goalValue: 50,
                    goalUnit: "min"
                )
            )
            .tint(.blue)
        }
    }
}
