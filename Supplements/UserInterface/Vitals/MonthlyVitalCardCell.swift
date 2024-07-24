//
//  MonthlyVitalCardCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

struct MonthlyVitalCardCell: View {
    let title: String
    let systemImage: String
    let subtitleText: String
    let metricValue: String
    let isIncreasing: Bool

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Label(title, systemImage: systemImage)
                    .bold()
                    .font(.title3)

                Spacer()

                Image(systemName: isIncreasing ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundStyle(.tint, .background.secondary)
                    .font(.largeTitle)
                    .bold()

            }

            Spacer()

            HStack(alignment: .bottom) {
                Text(subtitleText)
                    .font(.body)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(metricValue)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            MonthlyVitalCardCell(
                title: "Activity Level",
                systemImage: "figure.run",
                subtitleText: "Basal: 1756 Cal\nActive: 642 Cal",
                metricValue: "Moderate",
                isIncreasing: true
            )
            .tint(.green)
            MonthlyVitalCardCell(
                title: "Sleep Quality",
                systemImage: "moon.zzz.fill",
                subtitleText: "45% Core\n12% Deep",
                metricValue: "Good",
                isIncreasing: true
            )
            .tint(.coreSleep)
        }
        .padding()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}
