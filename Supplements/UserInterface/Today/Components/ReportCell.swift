//
//  ReportCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI

extension ReportCell {
    enum ReportKind {
        case morning
        case evening

        var systemImage: String {
            switch self {
            case .morning: "sunrise.fill"
            case .evening: "sunset.fill"
            }
        }

        var title: String {
            switch self {
            case .morning: "Morning Report"
            case .evening: "Evening Report"
            }
        }

        var subtitle: String {
            switch self {
            case .morning: "Everything you need to start your day."
            case .evening: "Wind down and review your day."
            }
        }

        var colors: [Color] {
            switch self {
            case .morning: [.mutedRed, .mutedOrange, .mutedYellow]
            case .evening: [.mutedPurple, .mutedPink]
            }
        }
    }
}

struct ReportCell: View {
    let kind: ReportKind

    var body: some View {
        HStack {
            Image(systemName: kind.systemImage)
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: kind.colors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            VStack(alignment: .leading) {
                Text(kind.title)
                    .font(.title3)
                    .bold()
                    .fontDesign(.rounded)
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            DisclosureIndicator()
        }
        .cardContainer(
            fill: LinearGradient(
                colors: kind.colors,
                startPoint: .bottom,
                endPoint: .top
            ).opacity(0.3),
            stroke: LinearGradient(
                colors: kind.colors,
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    ScrollView {
        VStack {
            ReportCell(kind: .morning)
            ReportCell(kind: .evening)
        }
        .padding()
    }
    .gradientRootBackground()
}
