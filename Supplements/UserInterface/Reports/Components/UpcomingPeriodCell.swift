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
                Text("Upcoming Period")
                    .bold()

                Text("Your period is expected to start by \(DateFormatter.justDateMedium.string(from: predictedPeriodDate)).")
            }

            Spacer(minLength: 0)

            DisclosureIndicator()
        }
    }
}

#Preview {
    UpcomingPeriodCell(predictedPeriodDate: .now)
}
