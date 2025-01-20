//
//  UpcomingPeriodCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-11.
//

import SwiftUI

struct UpcomingPeriodCell: View {
    let predictedPeriodDate: Date

    var body: some View {
        HStack(spacing: 16) {
            DayCapsule(
                dayNumber: "",
                highlightKind: .partial,
                isToday: false
            )
            .frame(width: 50)

            VStack(alignment: .leading) {
                Text(title)
                    .bold()

                Text(summary)
            }

            Spacer(minLength: 0)

            DisclosureIndicator()
        }
    }
}

private extension UpcomingPeriodCell {

    var isLate: Bool {
        let startOfDay = Calendar.current.startOfDay(for: .now)

        return predictedPeriodDate < startOfDay
    }

    var title: String {
        if isLate {
            "Late Period"
        } else {
            "Upcoming Period"
        }
    }

    var summary: String {
        if isLate {
            "Your period is late. It was predicted to start \(DateFormatter.justRelativeDateMedium.string(from: predictedPeriodDate))."
        } else {
            "Your period is expected to start \(DateFormatter.justRelativeDateMedium.string(from: predictedPeriodDate))."
        }
    }
}

#Preview {
    List {
        UpcomingPeriodCell(predictedPeriodDate: .now.addingTimeInterval(3600 * 24 * -3))
        UpcomingPeriodCell(predictedPeriodDate: .now.addingTimeInterval(3600 * 24 * -1))
        UpcomingPeriodCell(predictedPeriodDate: .now)
        UpcomingPeriodCell(predictedPeriodDate: .now.addingTimeInterval(3600 * 24 * 2))
    }
    .listStyle(.plain)
}
