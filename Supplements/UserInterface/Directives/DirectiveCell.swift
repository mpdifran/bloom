//
//  DirectiveCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-20.
//

import SwiftUI
import OpenAPIClient

struct DirectiveCell: View {
    let sleepActivity: SleepSuggestionModel

    @State private var hasTaken = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(sleepActivity.title)
                    .font(.title3)
                    .bold()

                Spacer()

                Circle()
                    .fill(.tint)
                    .frame(square: 40)
                    .overlay {
                        Image(systemName: sleepActivity.sfSymbol)
                            .foregroundStyle(.white)
                            .symbolVariant(.fill)
                    }
            }
            .padding(.top)

            Text(sleepActivity.description)
                .foregroundStyle(.secondary)

            Text("Revisit on \(sleepActivity.revisitDate, formatter: DateFormatter.justDateMedium)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 4)

            Divider()

            HStack {
                Text("Goal")
                    .fontDesign(.rounded)
                    .bold()

                Spacer()

                Text("\(sleepActivity.goalValue, specifier: "%.0f") \(sleepActivity.goalUnit)")
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.tint)
            }
            .font(.headline)
            .padding(.vertical, 6)

            Divider()

            DirectiveCompleteButton("Mark as Done", isComplete: hasTaken) {
                hasTaken.toggle()
                feedbackGenerator.impactOccurred()
            }
        }
        .tint(sleepActivity.color)
        .onAppear {
            feedbackGenerator.prepare()
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
                    sfSymbol: "pills",
                    tintColor: "#0088FF",
                    startDate: .now,
                    revisitDate: Date(timeIntervalSinceNow: 12400),
                    goalValue: 3,
                    goalUnit: "mg"
                )
            )
            .tint(.blue)
        }
    }
}
